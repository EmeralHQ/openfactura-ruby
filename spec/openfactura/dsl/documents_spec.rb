# frozen_string_literal: true

require "base64"

RSpec.describe Openfactura::DSL::Documents do
  let(:client) { instance_double(Openfactura::Client) }
  let(:documents) { described_class.new(client) }

  let(:receiver) do
    Openfactura::DSL::Receiver.new(
      rut: "76430498-5",
      business_name: "HOSTY SPA",
      business_activity: "ACTIVIDADES DE CONSULTORIA",
      contact: "Juan Pérez",
      address: "ARTURO PRAT 527",
      commune: "Curicó"
    )
  end

  let(:issuer) do
    Openfactura::DSL::Issuer.new(
      rut: "76795561-8",
      business_name: "HAULMER SPA",
      business_activity: "VENTA AL POR MENOR",
      economic_activity_code: "479100",
      address: "ARTURO PRAT 527",
      commune: "Curicó",
      sii_branch_code: "81303347"
    )
  end

  let(:item) do
    Openfactura::DSL::DteItem.new(
      line_number: 1,
      name: "Producto",
      quantity: 1,
      price: 2000,
      amount: 2000
    )
  end

  let(:totals) do
    Openfactura::DSL::Totals.new(
      total_amount: 2380,
      tax_rate: "19"
    )
  end

  let(:dte) do
    Openfactura::DSL::Dte.new(
      type: 33,
      receiver: receiver,
      items: [item],
      totals: totals
    )
  end

  describe "#emit" do
    let(:success_response) do
      {
        TOKEN: "test-token-123",
        FOLIO: 12345,
        PDF: "base64pdfcontent",
        XML: "base64xmlcontent"
      }
    end

    context "with valid DTE and issuer" do
      it "emits a document successfully" do
        expect(client).to receive(:post).with(
          "/v2/dte/document",
          body: hash_including(dte: hash_including(Encabezado: anything)),
          headers: hash_including("Idempotency-Key" => anything)
        ).and_return(success_response)

        response = documents.emit(dte: dte, issuer: issuer, response: ["PDF", "XML", "FOLIO", "TOKEN"])

        expect(response).to be_a(Openfactura::DocumentResponse)
        expect(response.token).to eq("test-token-123")
        expect(response.folio).to eq(12345)
        expect(response.pdf).to eq("base64pdfcontent")
        expect(response.xml).to eq("base64xmlcontent")
      end

      it "generates idempotency_key if not provided" do
        allow(SecureRandom).to receive(:uuid).and_return("generated-uuid-123")

        expect(client).to receive(:post).with(
          "/v2/dte/document",
          body: anything,
          headers: hash_including("Idempotency-Key" => "generated-uuid-123")
        ).and_return(success_response)

        response = documents.emit(dte: dte, issuer: issuer)

        expect(response.idempotency_key).to eq("generated-uuid-123")
      end

      it "uses provided idempotency_key" do
        custom_key = "my-custom-key-12345"

        expect(client).to receive(:post).with(
          "/v2/dte/document",
          body: anything,
          headers: hash_including("Idempotency-Key" => custom_key)
        ).and_return(success_response)

        response = documents.emit(dte: dte, issuer: issuer, idempotency_key: custom_key)

        expect(response.idempotency_key).to eq(custom_key)
      end

      it "includes custom fields in request body" do
        custom_fields = { informationNote: "Nota informativa", paymentNote: "Pago a 30 días" }

        expect(client).to receive(:post).with(
          "/v2/dte/document",
          body: hash_including(custom: custom_fields),
          headers: anything
        ).and_return(success_response)

        documents.emit(dte: dte, issuer: issuer, custom: custom_fields)
      end

      it "includes iva_exceptional in request body" do
        iva_exceptional = ["ARTESANO"]

        expect(client).to receive(:post).with(
          "/v2/dte/document",
          body: hash_including(ivaExceptional: iva_exceptional),
          headers: anything
        ).and_return(success_response)

        documents.emit(dte: dte, issuer: issuer, iva_exceptional: iva_exceptional)
      end

      it "includes send_email in request body" do
        send_email = {
          to: "cliente@example.com",
          subject: "Su factura electrónica",
          body: "Adjunto encontrará su factura"
        }

        expect(client).to receive(:post).with(
          "/v2/dte/document",
          body: hash_including(sendEmail: send_email),
          headers: anything
        ).and_return(success_response)

        documents.emit(dte: dte, issuer: issuer, send_email: send_email)
      end

      it "sets issuer in DTE if not already set" do
        dte_without_issuer = Openfactura::DSL::Dte.new(
          type: 33,
          receiver: receiver,
          items: [item],
          totals: totals
        )

        expect(client).to receive(:post).and_return(success_response)

        documents.emit(dte: dte_without_issuer, issuer: issuer)

        expect(dte_without_issuer.issuer).to eq(issuer)
      end
    end

    context "with invalid arguments" do
      it "raises ArgumentError if dte is not a Dte object" do
        expect do
          documents.emit(dte: {}, issuer: issuer)
        end.to raise_error(ArgumentError, "dte must be a Dte object")
      end

      it "raises ArgumentError if issuer is not an Issuer object" do
        expect do
          documents.emit(dte: dte, issuer: {})
        end.to raise_error(ArgumentError, "issuer must be an Issuer object")
      end
    end

    context "with API errors" do
      it "raises DocumentError when API returns error structure" do
        error_response = {
          error: {
            message: "Faltan datos obligatorios",
            code: "OF-01",
            details: [
              { field: "Encabezado.Emisor.RUTEmisor", issue: "Campo requerido" }
            ]
          }
        }

        api_error = Openfactura::ApiError.new("Bad Request", status_code: 400, response_body: error_response)

        expect(client).to receive(:post).and_raise(api_error)

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::DocumentError) do |error|
          expect(error.code).to eq("OF-01")
          expect(error.message).to eq("Faltan datos obligatorios")
          expect(error.has_details?).to be true
          expect(error.error_fields).to include("Encabezado.Emisor.RUTEmisor")
        end
      end

      it "raises DocumentError when API returns error structure as string" do
        error_response_string = {
          error: {
            message: "Tipo Dte no soportado",
            code: "OF-05"
          }
        }.to_json

        api_error = Openfactura::ApiError.new("Bad Request", status_code: 400, response_body: error_response_string)

        expect(client).to receive(:post).and_raise(api_error)

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::DocumentError) do |error|
          expect(error.code).to eq("OF-05")
          expect(error.message).to eq("Tipo Dte no soportado")
        end
      end

      it "raises ApiError when response doesn't contain error structure" do
        api_error = Openfactura::ApiError.new("Internal Server Error", status_code: 500, response_body: { message: "Server error" })

        expect(client).to receive(:post).and_raise(api_error)

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::ApiError)
      end
    end

    describe "receiver validation" do
      it "raises ValidationError before sending request when receiver is missing required fields" do
        issuer = Openfactura::DSL::Issuer.new(
          rut: "76795561-8",
          business_name: "HAULMER SPA",
          business_activity: "VENTA AL POR MENOR",
          economic_activity_code: "479100",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        )

        # Create receiver with missing required fields
        receiver = Openfactura::DSL::Receiver.new(
          rut: "76430498-5",
          business_name: "HOSTY SPA"
          # Missing: business_activity, contact, address, commune
        )

        dte = Openfactura::DSL::Dte.new(
          type: 33,
          receiver: receiver,
          items: [
            Openfactura::DSL::DteItem.new(
              line_number: 1,
              name: "Test",
              quantity: 1,
              price: 1000,
              amount: 1000
            )
          ],
          totals: Openfactura::DSL::Totals.new(
            total_amount: 1190,
            tax_rate: "19"
          )
        )

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::ValidationError) do |error|
          expect(error.message).to include("Receiver validation failed")
          expect(error.message).to include("business_activity")
          expect(error.message).to include("contact")
          expect(error.message).to include("address")
          expect(error.message).to include("commune")
          expect(error.errors[:receiver]).to be_an(Array)
        end
      end

      it "raises ValidationError before sending request when totals is missing required fields" do
        issuer = Openfactura::DSL::Issuer.new(
          rut: "76795561-8",
          business_name: "HAULMER SPA",
          business_activity: "VENTA AL POR MENOR",
          economic_activity_code: "479100",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        )

        receiver = Openfactura::DSL::Receiver.new(
          rut: "76430498-5",
          business_name: "HOSTY SPA",
          business_activity: "ACTIVIDADES DE CONSULTORIA",
          contact: "Juan Pérez",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        )

        # Create totals with missing required field total_amount
        totals = Openfactura::DSL::Totals.new(
          # Missing: total_amount
        )

        dte = Openfactura::DSL::Dte.new(
          type: 33,
          receiver: receiver,
          items: [
            Openfactura::DSL::DteItem.new(
              line_number: 1,
              name: "Test",
              quantity: 1,
              price: 1000,
              amount: 1000
            )
          ],
          totals: totals
        )

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::ValidationError) do |error|
          expect(error.message).to include("Totals validation failed")
          expect(error.message).to include("total_amount")
          expect(error.message).to include("MntTotal")
          expect(error.errors[:totals]).to be_an(Array)
        end
      end

      it "raises ValidationError before sending request when issuer is missing required fields" do
        receiver = Openfactura::DSL::Receiver.new(
          rut: "76430498-5",
          business_name: "HOSTY SPA",
          business_activity: "ACTIVIDADES DE CONSULTORIA",
          contact: "Juan Pérez",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        )

        # Create issuer with missing required fields
        issuer = Openfactura::DSL::Issuer.new(
          rut: "76795561-8",
          business_name: "HAULMER SPA"
          # Missing: business_activity, economic_activity_code, address, commune
        )

        dte = Openfactura::DSL::Dte.new(
          type: 33,
          receiver: receiver,
          items: [
            Openfactura::DSL::DteItem.new(
              line_number: 1,
              name: "Test",
              quantity: 1,
              price: 1000,
              amount: 1000
            )
          ],
          totals: Openfactura::DSL::Totals.new(
            total_amount: 1190,
            tax_rate: "19"
          ),
          issuer: issuer
        )

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::ValidationError) do |error|
          expect(error.message).to include("Issuer validation failed")
          expect(error.message).to include("business_activity")
          expect(error.message).to include("economic_activity_code")
          expect(error.message).to include("address")
          expect(error.message).to include("commune")
          expect(error.errors[:issuer]).to be_an(Array)
        end
      end

      it "raises ValidationError before sending request when item is missing required fields" do
        issuer = Openfactura::DSL::Issuer.new(
          rut: "76795561-8",
          business_name: "HAULMER SPA",
          business_activity: "VENTA AL POR MENOR",
          economic_activity_code: "479100",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        )

        receiver = Openfactura::DSL::Receiver.new(
          rut: "76430498-5",
          business_name: "HOSTY SPA",
          business_activity: "ACTIVIDADES DE CONSULTORIA",
          contact: "Juan Pérez",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        )

        # Create item with missing required fields
        item = Openfactura::DSL::DteItem.new(
          line_number: 1,
          name: "Producto"
          # Missing: quantity, price, amount
        )

        dte = Openfactura::DSL::Dte.new(
          type: 33,
          receiver: receiver,
          items: [item],
          totals: Openfactura::DSL::Totals.new(
            total_amount: 1190,
            tax_rate: "19"
          )
        )

        expect do
          documents.emit(dte: dte, issuer: issuer)
        end.to raise_error(Openfactura::ValidationError) do |error|
          expect(error.message).to include("DteItem validation failed")
          expect(error.message).to include("quantity")
          expect(error.message).to include("price")
          expect(error.message).to include("amount")
          expect(error.errors[:dte_item]).to be_an(Array)
        end
      end
    end
  end

  describe "#find_by_token" do
    it "finds a document by token with json value" do
      token = "test-token-123"
      response_data = {
        id: 1,
        token: token,
        folio: 12345,
        status: "sent"
      }

      expect(client).to receive(:get).with("/v2/dte/document/#{token}/json").and_return(response_data)

      response = documents.find_by_token(token: token, value: "json")
      expect(response).to be_a(Openfactura::DocumentQueryResponse)
      expect(response.token).to eq(token)
      expect(response.query_type).to eq("json")
      expect(response.has_document?).to be true
      expect(response.document).to be_a(Openfactura::Document)
      expect(response.document.id).to eq(1)
      expect(response.document.folio).to eq(12345)
      expect(response.document.status).to eq("sent")
    end

    it "finds a document by token with status value" do
      token = "test-token-123"
      status_string = "Aceptado"

      expect(client).to receive(:get).with("/v2/dte/document/#{token}/status").and_return(status_string)

      response = documents.find_by_token(token: token, value: "status")
      expect(response).to be_a(Openfactura::DocumentQueryResponse)
      expect(response.token).to eq(token)
      expect(response.query_type).to eq("status")
      expect(response.status).to eq("Aceptado")
      expect(response.has_document?).to be true
      expect(response.document.status).to eq("Aceptado")
    end

    it "finds a document by token with pdf value" do
      token = "test-token-123"
      pdf_binary = "pdf binary content"
      base64_content = Base64.encode64(pdf_binary)
      response_data = {
        pdf: base64_content,
        folio: 12345
      }

      expect(client).to receive(:get).with("/v2/dte/document/#{token}/pdf").and_return(response_data)

      response = documents.find_by_token(token: token, value: "pdf")
      expect(response).to be_a(Openfactura::DocumentQueryResponse)
      expect(response.token).to eq(token)
      expect(response.query_type).to eq("pdf")
      expect(response.pdf).to eq(base64_content)
      expect(response.folio).to eq(12345)
      expect(response.decode_pdf).to eq(pdf_binary)
    end

    it "finds a document by token with xml value" do
      token = "test-token-123"
      response_data = {
        xml: "base64xmlcontent",
        folio: 12345
      }

      expect(client).to receive(:get).with("/v2/dte/document/#{token}/xml").and_return(response_data)

      response = documents.find_by_token(token: token, value: "xml")
      expect(response).to be_a(Openfactura::DocumentQueryResponse)
      expect(response.token).to eq(token)
      expect(response.query_type).to eq("xml")
      expect(response.xml).to eq("base64xmlcontent")
      expect(response.folio).to eq(12345)
    end

    it "finds a document by token with cedible value" do
      token = "test-token-123"
      response_data = {
        cedible: "base64cediblecontent",
        folio: 12345
      }

      expect(client).to receive(:get).with("/v2/dte/document/#{token}/cedible").and_return(response_data)

      response = documents.find_by_token(token: token, value: "cedible")
      expect(response).to be_a(Openfactura::DocumentQueryResponse)
      expect(response.token).to eq(token)
      expect(response.query_type).to eq("cedible")
      expect(response.cedible).to eq("base64cediblecontent")
      expect(response.folio).to eq(12345)
    end

    it "raises ArgumentError for invalid value" do
      token = "test-token-123"
      expect do
        documents.find_by_token(token: token, value: "invalid")
      end.to raise_error(ArgumentError, /value must be one of/)
    end

    it "raises ArgumentError for empty token" do
      expect do
        documents.find_by_token(token: "", value: "json")
      end.to raise_error(ArgumentError, "token is required")
    end

    it "raises ArgumentError for nil token" do
      expect do
        documents.find_by_token(token: nil, value: "json")
      end.to raise_error(ArgumentError, "token is required")
    end
  end
end
