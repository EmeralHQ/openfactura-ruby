# frozen_string_literal: true

require "logger"

RSpec.describe Openfactura do
  describe ".configure" do
    it "configures the SDK" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      expect(Openfactura::Config.api_key).to eq("test-key")
      expect(Openfactura::Config.environment).to eq(:sandbox)
    end
  end

  describe ".documents" do
    it "returns documents DSL instance" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      expect(described_class.documents).to be_a(Openfactura::DSL::Documents)
    end
  end

  describe ".organizations" do
    it "returns organizations DSL instance" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      expect(described_class.organizations).to be_a(Openfactura::DSL::Organizations)
    end
  end

  describe ".reset!" do
    it "resets all instances" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      documents = described_class.documents
      described_class.reset!

      expect(described_class.documents).not_to be(documents)
    end
  end

  describe ".config" do
    it "returns the Config class" do
      expect(described_class.config).to be(Openfactura::Config)
    end
  end

  describe "the default client (facade)" do
    after { described_class.reset! }

    it "builds it from Config on first use" do
      described_class.configure { |config| config.api_key = "facade-key" }

      expect(described_class.client.api_key).to eq("facade-key")
    end

    it "reuses the same client across calls" do
      described_class.configure { |config| config.api_key = "facade-key" }

      expect(described_class.client).to be(described_class.client)
    end

    it "shares one client between .documents and .organizations" do
      described_class.configure { |config| config.api_key = "facade-key" }

      expect(described_class.documents).to be(described_class.client.documents)
      expect(described_class.organizations).to be(described_class.client.organizations)
    end

    # Antes el cliente se memoizaba en el primer uso y todo `configure` posterior se ignoraba en
    # silencio: se seguían emitiendo DTEs con la key vieja sin ninguna señal.
    it "rebuilds the client when reconfigured, instead of silently ignoring the change" do
      described_class.configure { |config| config.api_key = "key-one" }
      expect(described_class.client.api_key).to eq("key-one")

      described_class.configure { |config| config.api_key = "key-two" }
      expect(described_class.client.api_key).to eq("key-two")
    end

    it "defers validation until the client is actually built" do
      described_class.configure { |config| config.api_key = nil }

      expect { described_class.client }.to raise_error(Openfactura::ValidationError, /API key is required/)
    end

    it "carries every configured option through to the client" do
      logger = Logger.new(IO::NULL)
      described_class.configure do |config|
        config.api_key = "facade-key"
        config.environment = :production
        config.timeout = 45
        config.logger = logger
      end

      client = described_class.client
      expect(client.environment).to eq(:production)
      expect(client.timeout).to eq(45)
      expect(client.logger).to be(logger)
      expect(client.base_url).to eq(Openfactura::Config::PRODUCTION_URL)
    ensure
      described_class.configure do |config|
        config.environment = :sandbox
        config.timeout = 30
        config.logger = nil
      end
    end
  end

  describe "multi-tenancy" do
    # El caso que motiva todo el rediseño: la fachada sirve al consumidor de un solo contribuyente,
    # y una app multi-tenant construye un cliente por tenant sin que ninguno vea al otro.
    it "keeps a directly-built client independent from the facade's default client" do
      described_class.configure { |config| config.api_key = "default-key" }

      tenant = Openfactura::Client.new(api_key: "tenant-key", environment: :production)

      expect(described_class.client.api_key).to eq("default-key")
      expect(tenant.api_key).to eq("tenant-key")
      expect(described_class.client.base_url).to eq(Openfactura::Config::SANDBOX_URL)
      expect(tenant.base_url).to eq(Openfactura::Config::PRODUCTION_URL)
    ensure
      described_class.reset!
    end

    it "gives each tenant client its own DSL bound to its own credentials" do
      a = Openfactura::Client.new(api_key: "key-a")
      b = Openfactura::Client.new(api_key: "key-b")

      stub_a = stub_request(:get, "#{Openfactura::Config::SANDBOX_URL}/v2/dte/organization")
        .with(headers: { "apikey" => "key-a" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
      stub_b = stub_request(:get, "#{Openfactura::Config::SANDBOX_URL}/v2/dte/organization")
        .with(headers: { "apikey" => "key-b" })
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      a.organizations.current
      b.organizations.current

      expect(stub_a).to have_been_requested
      expect(stub_b).to have_been_requested
    end
  end
end
