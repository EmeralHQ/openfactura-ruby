# frozen_string_literal: true

require "spec_helper"
require "openfactura/sandbox_companies"

RSpec.describe "Open Factura API Integration", :integration do
  # Skip tests if API is not available
  before(:all) do
    unless RSpec::Support::Helpers.api_available?
      skip "Open Factura API is not available. Skipping integration tests."
    end
  end

  before(:each) do
    # Configure with Haulmer sandbox company
    @company = Openfactura::SandboxCompanies.configure_with(:haulmer, environment: :sandbox)

    # Verify configuration
    expect(Openfactura::Config.api_key).to eq(@company[:apikey])
    expect(Openfactura::Config.environment).to eq(:sandbox)
  end

  describe "Complete DTE Emission Flow" do
    it "emits a DTE successfully with full response verification" do
      # Step 1: Get current organization
      organization = Openfactura.organizations.current
      expect(organization).to be_a(Openfactura::Organization)
      expect(organization.rut).to eq(@company[:rut_emisor])
      # Note: API may return slightly different name, so we check it contains the company name
      expect(organization.razon_social).to include(@company[:razon_social].split.first)

      # Step 2: Convert organization to Issuer
      issuer = Openfactura.organizations.current_as_issuer
      expect(issuer).to be_a(Openfactura::DSL::Issuer)
      expect(issuer.rut).to eq(@company[:rut_emisor])
      # Note: API may return slightly different name, so we check it contains the company name
      expect(issuer.business_name).to include(@company[:razon_social].split.first)

      # Step 3: Create Receiver
      receiver = Openfactura::DSL::Receiver.new(
        rut: "76430498-5",  # HOSTY SPA (another sandbox company)
        business_name: "HOSTY SPA",
        business_activity: "SERVICIOS DE INFORMATICA",
        contact: "Contacto HOSTY",
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      # Step 4: Create DTE Items
      items = [
        Openfactura::DSL::DteItem.new(
          line_number: 1,
          name: "Producto de Prueba",
          quantity: 1,
          price: 10000,
          description: "Producto de prueba para integración"
        ),
        Openfactura::DSL::DteItem.new(
          line_number: 2,
          name: "Servicio de Prueba",
          quantity: 2,
          price: 5000,
          description: "Servicio de prueba para integración"
        )
      ]

      # Step 5: Create Totals
      totals = Openfactura::DSL::Totals.new(
        tax_rate: "19"
      )

      # Step 6: Create DTE
      dte = Openfactura::DSL::Dte.new(
        type: 33,  # Factura Electrónica
        emission_date: Date.today.strftime("%Y-%m-%d"),
        receiver: receiver,
        items: items,
        totals: totals
      )

      expect(dte.type).to eq(33)
      expect(dte.receiver.rut).to eq("76430498-5")
      expect(dte.items.length).to eq(2)
      expect(dte.totals).to be_a(Openfactura::DSL::Totals)

      # Step 7: Emit document requesting PDF, XML, FOLIO, TOKEN
      response = nil
      expect do
        response = Openfactura.documents.emit(
          dte: dte,
          issuer: issuer,
          response: ["PDF", "XML", "FOLIO", "TOKEN"]
        )
      end.not_to raise_error

      # Step 8: Verify response structure
      expect(response).to be_a(Openfactura::DocumentResponse)
      expect(response.success?).to be true

      # Step 9: Verify all requested data is present
      expect(response.token).to be_a(String)
      expect(response.token).not_to be_empty
      expect(response.folio).to be_a(Integer)
      expect(response.folio).to be > 0
      expect(response.idempotency_key).to be_a(String)
      expect(response.idempotency_key).not_to be_empty

      # Step 10: Verify PDF is present and can be decoded
      expect(response.pdf).to be_a(String)
      expect(response.pdf).not_to be_empty

      pdf_binary = response.decode_pdf
      expect(pdf_binary).to be_a(String)
      expect(pdf_binary.length).to be > 0
      # PDF files start with %PDF
      expect(pdf_binary[0..4]).to eq("%PDF-")

      # Step 11: Verify XML is present and can be decoded
      expect(response.xml).to be_a(String)
      expect(response.xml).not_to be_empty

      xml_content = response.decode_xml
      expect(xml_content).to be_a(String)
      expect(xml_content.length).to be > 0
      # XML should contain DTE structure
      expect(xml_content).to include("<?xml")
      expect(xml_content).to include("DTE")
      expect(xml_content).to include("Encabezado")
      expect(xml_content).to include("Detalle")

      # Step 12: Verify response hash
      response_hash = response.to_h
      expect(response_hash).to be_a(Hash)
      expect(response_hash[:token]).to eq(response.token)
      expect(response_hash[:folio]).to eq(response.folio)
      expect(response_hash[:idempotency_key]).to eq(response.idempotency_key)
      expect(response_hash[:pdf]).to eq(response.pdf)
      expect(response_hash[:xml]).to eq(response.xml)

      # Step 13: Query document by token
      query_response = nil
      expect do
        query_response = Openfactura.documents.find_by_token(token: response.token, value: "json")
      end.not_to raise_error

      expect(query_response).to be_a(Openfactura::DocumentQueryResponse)
      expect(query_response.token).to eq(response.token)
      expect(query_response.query_type).to eq("json")
      expect(query_response.has_document?).to be true
      expect(query_response.document).to be_a(Openfactura::Document)
      # Document uses dte_id for the token
      expect(query_response.document.dte_id).to eq(response.token)
    end

    it "handles idempotency correctly with same key" do
      # Configure
      Openfactura::SandboxCompanies.configure_with(:haulmer, environment: :sandbox)
      issuer = Openfactura.organizations.current_as_issuer

      # Create minimal DTE
      dte = Openfactura::DSL::Dte.new(
        type: 33,
        emission_date: Date.today.strftime("%Y-%m-%d"),
        receiver: Openfactura::DSL::Receiver.new(
          rut: "76430498-5",
          business_name: "HOSTY SPA",
          business_activity: "SERVICIOS DE INFORMATICA",
          contact: "Contacto HOSTY",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        ),
        items: [
          Openfactura::DSL::DteItem.new(
            line_number: 1,
            name: "Test",
            quantity: 1,
            price: 1000
          )
        ],
        totals: Openfactura::DSL::Totals.new(
          tax_rate: "19"
        )
      )

      # First emission
      custom_key = "test-idempotency-#{Time.now.to_i}-#{SecureRandom.hex(4)}"
      response1 = Openfactura.documents.emit(
        dte: dte,
        issuer: issuer,
        response: ["TOKEN"],
        idempotency_key: custom_key
      )

      expect(response1.idempotency_key).to eq(custom_key)
      first_token = response1.token
      expect(first_token).not_to be_nil

      # Second emission with same key
      # Note: Open Factura API returns error OF-06 when idempotency key is reused
      # The error includes the original token in the details
      expect do
        Openfactura.documents.emit(
          dte: dte,
          issuer: issuer,
          response: ["TOKEN"],
          idempotency_key: custom_key
        )
      end.to raise_error do |error|
        # Should be either DocumentError or ApiError (depending on parsing)
        expect([Openfactura::DocumentError, Openfactura::ApiError]).to include(error.class)

        # If it's a DocumentError, verify the code
        if error.is_a?(Openfactura::DocumentError)
          expect(error.code).to eq("OF-06")
          expect(error.has_details?).to be true
        else
          # If it's an ApiError, verify it mentions OF-06
          expect(error.message).to include("OF-06")
        end

        # The error should mention idempotency or emitido
        error_message_lower = error.message.downcase
        expect(error_message_lower.include?("idempotency") || error_message_lower.include?("emitido")).to be true
      end
    end

    it "raises DocumentError with invalid DTE data" do
      # Configure
      Openfactura::SandboxCompanies.configure_with(:haulmer, environment: :sandbox)
      issuer = Openfactura.organizations.current_as_issuer

      # Create DTE with invalid RUT (but valid structure to pass validation)
      dte = Openfactura::DSL::Dte.new(
        type: 33,
        emission_date: Date.today.strftime("%Y-%m-%d"),
        receiver: Openfactura::DSL::Receiver.new(
          rut: "INVALID-RUT",  # Invalid RUT (will fail API validation, not local validation)
          business_name: "TEST",
          business_activity: "TEST ACTIVITY",
          contact: "TEST CONTACT",
          address: "TEST",
          commune: "TEST"
        ),
        items: [
          Openfactura::DSL::DteItem.new(
            line_number: 1,
            name: "Test",
            quantity: 1,
            price: 1000
          )
        ],
        totals: Openfactura::DSL::Totals.new(
          tax_rate: "19"
        )
      )

      expect do
        Openfactura.documents.emit(
          dte: dte,
          issuer: issuer,
          response: ["TOKEN"]
        )
      end.to raise_error do |error|
        # Should be either DocumentError or ApiError
        expect([Openfactura::DocumentError, Openfactura::ApiError]).to include(error.class)
        expect(error.message).to be_a(String)
        expect(error.message).not_to be_empty

        # If it's a DocumentError, check additional attributes
        if error.is_a?(Openfactura::DocumentError)
          expect(error.code).to be_a(String)
          expect(error.error_description).to be_a(String)

          # May have details
          if error.has_details?
            expect(error.error_fields).to be_an(Array)
          end
        end
      end
    end

    it "verifies organization data retrieval" do
      # Configure
      Openfactura::SandboxCompanies.configure_with(:haulmer, environment: :sandbox)

      # Get organization
      organization = Openfactura.organizations.current

      expect(organization).to be_a(Openfactura::Organization)
      expect(organization.rut).to eq("76795561-8")
      # Note: API may return slightly different name
      expect(organization.razon_social).to include("HAULMER")
      expect(organization.direccion).to be_a(String)
      expect(organization.comuna).to be_a(String)

      # Verify primary activity
      primary_activity = organization.primary_activity
      expect(primary_activity).to be_a(Hash)
      expect(primary_activity[:giro] || primary_activity["giro"]).to be_a(String)

      # Verify issuer conversion
      issuer = Openfactura.organizations.current_as_issuer
      expect(issuer.rut).to eq(organization.rut)
      expect(issuer.business_name).to eq(organization.razon_social)
      expect(issuer.business_activity).to be_a(String)
      expect(issuer.economic_activity_code).to be_a(String)
    end

    it "verifies authorized documents retrieval" do
      # Configure
      Openfactura::SandboxCompanies.configure_with(:haulmer, environment: :sandbox)

      # Get authorized documents
      documents_info = Openfactura.organizations.documents

      expect(documents_info).to be_a(Hash)
      expect(documents_info[:rut] || documents_info["rut"]).to eq("76795561-8")
      expect(documents_info[:documentos] || documents_info["documentos"]).to be_an(Array)

      # Verify document structure
      documentos = documents_info[:documentos] || documents_info["documentos"]
      if documentos.any?
        first_doc = documentos.first
        # DTE type can be Integer or String
        dte_type = first_doc[:dte] || first_doc["dte"]
        expect([Integer, String]).to include(dte_type.class)
        # disponible may not be present in all responses
        disponible = first_doc[:disponible] || first_doc["disponible"]
        expect(disponible).to be_a(Integer) if disponible
      end
    end
  end
end
