# frozen_string_literal: true

require "spec_helper"
require "openfactura/sandbox_companies"
require "fileutils"

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
      # Item 1: 1 unidad a $12,345.50 = $12,345.50
      # Item 2: 2 unidades a $8,765.25 = $17,530.50
      # Net amount: $12,345.50 + $17,530.50 = $29,876.00
      # Tax (19%): $29,876.00 * 0.19 = $5,676.44
      # Total: $29,876.00 + $5,676.44 = $35,552.44
      items = [
        Openfactura::DSL::DteItem.new(
          line_number: 1,
          name: "Producto de Prueba",
          quantity: 1,
          price: 12345.50,
          amount: 12346,
          description: "Producto de prueba para integración"
        ),
        Openfactura::DSL::DteItem.new(
          line_number: 2,
          name: "Servicio de Prueba",
          quantity: 2,
          price: 8765.25,
          amount: 17531,
          description: "Servicio de prueba para integración"
        )
      ]

      # Step 5: Create Totals
      # Calculated values:
      # net_amount = 12345.50 + 17530.50 = 29876.00
      # tax_amount = 29876.00 * 0.19 = 5676.44
      # total_amount = 29876.00 + 5676.44 = 35552.44
      totals = Openfactura::DSL::Totals.new(
        total_amount: 35554,
        net_amount: 29876.00,
        tax_amount: 5677,
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
      expect(dte.totals.total_amount).to eq(35554)

      # Step 7: Emit document requesting PDF, XML, FOLIO, TOKEN
      response = nil
      begin
        response = Openfactura.documents.emit(
          dte: dte,
          issuer: issuer,
          response: ["PDF", "XML", "FOLIO", "TOKEN"]
        )
      rescue => e
        # Log error to file for debugging
        tmp_dir = File.join(__dir__, "..", "tmp")
        FileUtils.mkdir_p(tmp_dir) unless Dir.exist?(tmp_dir)

        log_filename = File.join(tmp_dir, "dte_emission_error_#{Time.now.strftime("%Y%m%d_%H%M%S")}.log")
        error_log = File.open(log_filename, "w", encoding: "UTF-8")

        error_log.puts "=" * 80
        error_log.puts "DTE EMISSION ERROR LOG"
        error_log.puts "=" * 80
        error_log.puts "Timestamp: #{Time.now.strftime("%Y-%m-%d %H:%M:%S %z")}"
        error_log.puts ""
        error_log.puts "Error Class: #{e.class}"
        error_log.puts "Error Message: #{e.message}"
        error_log.puts ""
        error_log.puts "Backtrace:"
        error_log.puts "-" * 80
        e.backtrace.each { |line| error_log.puts "  #{line}" }
        error_log.puts ""
        error_log.puts "=" * 80
        error_log.puts "DTE CONTEXT"
        error_log.puts "=" * 80
        error_log.puts "Type: #{dte.type}"
        error_log.puts "Emission Date: #{dte.emission_date}"
        error_log.puts "Receiver RUT: #{dte.receiver.rut}"
        error_log.puts "Receiver Name: #{dte.receiver.business_name}"
        error_log.puts "Issuer RUT: #{issuer.rut}"
        error_log.puts "Issuer Name: #{issuer.business_name}"
        error_log.puts "Items Count: #{dte.items.length}"
        error_log.puts ""
        error_log.puts "DTE Items:"
        dte.items.each_with_index do |item, index|
          error_log.puts "  Item #{index + 1}:"
          error_log.puts "    Line Number: #{item.line_number}"
          error_log.puts "    Name: #{item.name}"
          error_log.puts "    Quantity: #{item.quantity}"
          error_log.puts "    Price: #{item.price}"
          error_log.puts "    Amount: #{item.amount}" if item.respond_to?(:amount)
        end
        error_log.puts ""
        error_log.puts "DTE API Hash (first 2000 chars):"
        error_log.puts "-" * 80
        begin
          dte_hash = dte.to_api_hash
          dte_hash_str = dte_hash.inspect
          error_log.puts dte_hash_str[0..2000]
          error_log.puts "..." if dte_hash_str.length > 2000
        rescue => hash_error
          error_log.puts "Error generating DTE hash: #{hash_error.message}"
        end
        error_log.puts ""
        error_log.puts "=" * 80
        error_log.puts "END OF ERROR LOG"
        error_log.puts "=" * 80

        error_log.close
        puts "\n✗ Error guardado en: #{log_filename}"

        # Re-raise the error so the test fails
        raise e
      end

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

      # Step 11.5: Save PDF and XML to spec/tmp for manual verification
      tmp_dir = File.join(__dir__, "..", "tmp")
      FileUtils.mkdir_p(tmp_dir) unless Dir.exist?(tmp_dir)

      # Generate descriptive filenames with folio and token
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      pdf_filename = File.join(tmp_dir, "dte_folio_#{response.folio}_token_#{response.token[0..8]}_#{timestamp}.pdf")
      xml_filename = File.join(tmp_dir, "dte_folio_#{response.folio}_token_#{response.token[0..8]}_#{timestamp}.xml")

      # Write PDF file
      File.binwrite(pdf_filename, pdf_binary)
      puts "\n✓ PDF guardado en: #{pdf_filename}"

      # Write XML file
      File.write(xml_filename, xml_content, encoding: "UTF-8")
      puts "✓ XML guardado en: #{xml_filename}"

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
            price: 1000,
            amount: 1000
          )
        ],
        totals: Openfactura::DSL::Totals.new(
          total_amount: 1190,
          net_amount: 1000,
          tax_amount: 190,
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
            price: 1000,
            amount: 1000
          )
        ],
        totals: Openfactura::DSL::Totals.new(
          total_amount: 1190,
          net_amount: 1000,
          tax_amount: 190,
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
