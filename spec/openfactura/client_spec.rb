# frozen_string_literal: true

require "logger"
require "stringio"

RSpec.describe Openfactura::Client do
  let(:config) { Openfactura::Config }
  let(:client) { described_class.new(config) }

  before do
    config.api_key = "test-api-key"
    config.environment = :sandbox
    config.api_base_url = nil
  end

  describe "#get" do
    it "makes a GET request" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .with(headers: { "apikey" => "test-api-key", "Content-Type" => "application/json" })
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      response = client.get("/v1/test")
      expect(response["success"] || response[:success]).to be true
    end

    it "raises AuthenticationError on 401" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 401, body: "", headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::AuthenticationError)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 404, body: "", headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::NotFoundError)
    end
  end

  describe "#post" do
    it "makes a POST request with body" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .with(
          headers: { "apikey" => "test-api-key", "Content-Type" => "application/json" },
          body: "{\"name\":\"test\"}"
        )
        .to_return(status: 200, body: '{"id": 1}', headers: { "Content-Type" => "application/json" })

      response = client.post("/v1/test", body: { name: "test" })
      expect(response["id"] || response[:id]).to eq(1)
    end

    it "extracts error message from Open Factura error format" do
      error_response = {
        error: {
          message: "Faltan datos obligatorios",
          code: "OF-01",
          details: [
            { field: "Encabezado.Emisor.RUTEmisor", issue: "Campo requerido" },
            { field: "Encabezado.Receptor.RUTRecep", issue: "Campo requerido" }
          ]
        }
      }.to_json

      stub_request(:post, "#{config.base_url}/v1/test")
        .to_return(status: 400, body: error_response, headers: { "Content-Type" => "application/json" })

      expect do
        client.post("/v1/test", body: {})
      end.to raise_error(Openfactura::ApiError) do |error|
        # Verify error message includes code and message from Open Factura format
        expect(error.message).to include("[OF-01]")
        expect(error.message).to include("Faltan datos obligatorios")
        # Verify details are included in the message
        expect(error.message).to include("Encabezado.Emisor.RUTEmisor: Campo requerido")
        expect(error.message).to include("Encabezado.Receptor.RUTRecep: Campo requerido")
      end
    end

    it "includes error details in message for Open Factura format" do
      error_response = {
        error: {
          message: "Validación de Campos",
          code: "OF-10",
          details: [
            { field: "RUTRecep", issue: "El campo es requerido" },
            { field: "FchEmis", issue: "Formato de fecha inválido" }
          ]
        }
      }.to_json

      stub_request(:post, "#{config.base_url}/v1/test")
        .to_return(status: 400, body: error_response, headers: { "Content-Type" => "application/json" })

      expect do
        client.post("/v1/test", body: {})
      end.to raise_error(Openfactura::ApiError) do |error|
        expect(error.message).to include("[OF-10]")
        expect(error.message).to include("Validación de Campos")
        expect(error.message).to include("RUTRecep: El campo es requerido")
        expect(error.message).to include("FchEmis: Formato de fecha inválido")
      end
    end

    it "merges custom headers with the default headers" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .with(headers: { "apikey" => "test-api-key", "X-Custom" => "yes" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      expect { client.post("/v1/test", headers: { "X-Custom" => "yes" }, body: {}) }.not_to raise_error
    end
  end

  describe "#put" do
    it "makes a PUT request" do
      stub_request(:put, "#{config.base_url}/v1/test")
        .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })

      response = client.put("/v1/test")
      expect(response["ok"] || response[:ok]).to be true
    end
  end

  describe "#delete" do
    it "makes a DELETE request" do
      stub_request(:delete, "#{config.base_url}/v1/test")
        .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })

      response = client.delete("/v1/test")
      expect(response["ok"] || response[:ok]).to be true
    end
  end

  describe "HTTP error handling" do
    it "raises RateLimitError on 429" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 429, body: "", headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::RateLimitError, /Rate limit exceeded/)
    end

    it "raises ServerError on 500" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 500, body: "boom", headers: { "Content-Type" => "text/plain" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::ServerError)
    end

    it "raises ApiError on an unmapped 4xx without an error body" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 418, body: "", headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::ApiError, /418/)
    end

    it "preserves status_code and response_body on an unmapped 4xx error" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 418, body: '{"error":"teapot"}', headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::ApiError) do |error|
        expect(error.status_code).to eq(418)
        expect(error.response_body).to include("teapot")
      end
    end

    it "wraps a network timeout in an ApiError" do
      stub_request(:get, "#{config.base_url}/v1/test").to_timeout

      expect { client.get("/v1/test") }.to raise_error(Openfactura::ApiError, /Request timeout/)
    end

    it "preserves the original exception as the cause when wrapping a timeout" do
      stub_request(:get, "#{config.base_url}/v1/test").to_timeout

      expect { client.get("/v1/test") }.to raise_error(Openfactura::ApiError) do |error|
        expect(error.cause).to be_a(Timeout::Error)
      end
    end

    # Cada uno de estos es un fallo de transporte real: el request nunca llegó a producir una
    # respuesta HTTP, así que no hay status que mapear y ApiError es la traducción correcta.
    {
      "a refused connection" => Errno::ECONNREFUSED.new("Connection refused"),
      "a DNS resolution failure" => SocketError.new("Failed to open TCP connection"),
      "a TLS handshake failure" => OpenSSL::SSL::SSLError.new("certificate verify failed"),
      "a connection reset mid-response" => Errno::ECONNRESET.new("Connection reset by peer"),
    }.each do |description, exception|
      it "wraps #{description} in an ApiError" do
        stub_request(:get, "#{config.base_url}/v1/test").to_raise(exception)

        expect { client.get("/v1/test") }.to raise_error(Openfactura::ApiError, /Connection failed/)
      end
    end

    # Regresión de #12. Antes, un `rescue StandardError` convertía cualquier bug del propio gem en
    # un falso "error de API": el consumidor veía ApiError("Request failed: undefined method…"),
    # rescataba pensando que era la red, y el backtrace del bug real se perdía.
    it "lets a programming error propagate instead of disguising it as an API failure" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_raise(NoMethodError.new("undefined method `foo' for nil"))

      expect { client.get("/v1/test") }.to raise_error(NoMethodError, /undefined method/)
    end

    it "does not translate a non-transport StandardError into an ApiError" do
      stub_request(:get, "#{config.base_url}/v1/test").to_raise(RuntimeError.new("boom"))

      expect { client.get("/v1/test") }.to raise_error(RuntimeError, "boom")
    end

    it "extracts a flat top-level message from an error body without an error object" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .to_return(status: 400, body: '{"detail":"algo salió mal"}', headers: { "Content-Type" => "application/json" })

      expect { client.post("/v1/test", body: {}) }.to raise_error(Openfactura::ApiError, /algo salió mal/)
    end

    it "unwraps a nested message object from an error body" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .to_return(status: 400, body: '{"message":{"message":"nested detail"}}', headers: { "Content-Type" => "application/json" })

      expect { client.post("/v1/test", body: {}) }.to raise_error(Openfactura::ApiError, /nested detail/)
    end

    it "returns the raw body when the error body is not valid JSON" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .to_return(status: 400, body: "plain text failure", headers: { "Content-Type" => "text/plain" })

      expect { client.post("/v1/test", body: {}) }.to raise_error(Openfactura::ApiError, /plain text failure/)
    end
  end

  describe "request logging (secret redaction)" do
    let(:output) { StringIO.new }
    let(:logger) { Logger.new(output, level: Logger::DEBUG) }

    before { config.logger = logger }

    after { config.logger = nil }

    it "logs method and path, redacts the apikey, and never logs the request body" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      client.post("/v1/test", body: { rut: "11111111-1", amount: 5000 }, headers: { "Idempotency-Key" => "abc" })

      log = output.string
      expect(log).to include("[OpenFactura] POST /v1/test")
      expect(log).to include("[FILTERED]")           # apikey redacted
      expect(log).to include("Idempotency-Key")      # non-sensitive header still logged
      expect(log).not_to include("test-api-key")     # the real apikey value
      expect(log).not_to include("11111111-1")       # the DTE body (RUT) is never logged
    end
  end

  describe "per-instance connection isolation (multi-tenant)" do
    it "sends each client's own apikey instead of a shared class-level one" do
      config.api_key = "key-tenant-a"
      client_a = described_class.new(config)
      config.api_key = "key-tenant-b"
      client_b = described_class.new(config)

      stub_a = stub_request(:get, "#{config.base_url}/v1/a")
        .with(headers: { "apikey" => "key-tenant-a" }).to_return(status: 200, body: "{}")
      stub_b = stub_request(:get, "#{config.base_url}/v1/b")
        .with(headers: { "apikey" => "key-tenant-b" }).to_return(status: 200, body: "{}")

      expect { client_a.get("/v1/a") }.not_to raise_error
      expect { client_b.get("/v1/b") }.not_to raise_error
      expect(stub_a).to have_been_requested
      expect(stub_b).to have_been_requested
    end
  end
end
