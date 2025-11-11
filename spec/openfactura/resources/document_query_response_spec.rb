# frozen_string_literal: true

require_relative "../../../lib/openfactura/resources/document_query_response"
require "base64"

RSpec.describe Openfactura::DocumentQueryResponse do
  let(:token) { "test-token-123" }

  describe "#initialize" do
    context "with json query type" do
      it "initializes with document data" do
        response_data = {
          id: 1,
          token: token,
          folio: 12345,
          status: "sent",
          type: 33
        }

        response = described_class.new(
          token: token,
          query_type: "json",
          response_data: response_data
        )

        expect(response.token).to eq(token)
        expect(response.query_type).to eq("json")
        expect(response.has_document?).to be true
        expect(response.document).to be_a(Openfactura::Document)
        expect(response.document.id).to eq(1)
        expect(response.document.folio).to eq(12345)
        expect(response.document.status).to eq("sent")
      end
    end

    context "with status query type" do
      it "initializes with status string" do
        status_string = "Aceptado"

        response = described_class.new(
          token: token,
          query_type: "status",
          response_data: status_string
        )

        expect(response.token).to eq(token)
        expect(response.query_type).to eq("status")
        expect(response.status).to eq("Aceptado")
        expect(response.has_document?).to be true
        expect(response.document.status).to eq("Aceptado")
      end
    end

    context "with pdf query type" do
      it "initializes with pdf content" do
        pdf_binary = "pdf binary content"
        base64_content = Base64.encode64(pdf_binary)
        response_data = {
          pdf: base64_content,
          folio: 12345
        }

        response = described_class.new(
          token: token,
          query_type: "pdf",
          response_data: response_data
        )

        expect(response.token).to eq(token)
        expect(response.query_type).to eq("pdf")
        expect(response.pdf).to eq(base64_content)
        expect(response.folio).to eq(12345)
      end
    end

    context "with xml query type" do
      it "initializes with xml content" do
        xml_binary = "xml content"
        base64_content = Base64.encode64(xml_binary)
        response_data = {
          xml: base64_content,
          folio: 12345
        }

        response = described_class.new(
          token: token,
          query_type: "xml",
          response_data: response_data
        )

        expect(response.token).to eq(token)
        expect(response.query_type).to eq("xml")
        expect(response.xml).to eq(base64_content)
        expect(response.folio).to eq(12345)
      end
    end

    context "with cedible query type" do
      it "initializes with cedible content" do
        cedible_binary = "cedible content"
        base64_content = Base64.encode64(cedible_binary)
        response_data = {
          cedible: base64_content,
          folio: 12345
        }

        response = described_class.new(
          token: token,
          query_type: "cedible",
          response_data: response_data
        )

        expect(response.token).to eq(token)
        expect(response.query_type).to eq("cedible")
        expect(response.cedible).to eq(base64_content)
        expect(response.folio).to eq(12345)
      end
    end
  end

  describe "#content" do
    it "returns document for json query" do
      response_data = { id: 1, token: token, folio: 12345 }
      response = described_class.new(token: token, query_type: "json", response_data: response_data)
      expect(response.content).to be_a(Openfactura::Document)
    end

    it "returns status for status query" do
      response = described_class.new(token: token, query_type: "status", response_data: "Aceptado")
      expect(response.content).to eq("Aceptado")
    end

    it "returns pdf for pdf query" do
      response_data = { pdf: "base64content", folio: 12345 }
      response = described_class.new(token: token, query_type: "pdf", response_data: response_data)
      expect(response.content).to eq("base64content")
    end
  end

  describe "#decode_pdf" do
    it "decodes base64 PDF content" do
      pdf_binary = "pdf binary content"
      base64_content = Base64.encode64(pdf_binary)
      response_data = { pdf: base64_content, folio: 12345 }

      response = described_class.new(token: token, query_type: "pdf", response_data: response_data)
      expect(response.decode_pdf).to eq(pdf_binary)
    end

    it "returns nil if pdf is not available" do
      response_data = { id: 1, token: token }
      response = described_class.new(token: token, query_type: "json", response_data: response_data)
      expect(response.decode_pdf).to be_nil
    end
  end

  describe "#decode_xml" do
    it "decodes base64 XML content with ISO-8859-1 encoding" do
      xml_content = "xml content with special chars: áéíóú"
      base64_content = Base64.encode64(xml_content.encode("ISO-8859-1"))
      response_data = { xml: base64_content, folio: 12345 }

      response = described_class.new(token: token, query_type: "xml", response_data: response_data)
      decoded = response.decode_xml
      expect(decoded).to be_a(String)
      expect(decoded.encoding.name).to eq("UTF-8")
    end

    it "returns nil if xml is not available" do
      response_data = { id: 1, token: token }
      response = described_class.new(token: token, query_type: "json", response_data: response_data)
      expect(response.decode_xml).to be_nil
    end
  end

  describe "#decode_cedible" do
    it "decodes base64 cedible content" do
      cedible_binary = "cedible binary content"
      base64_content = Base64.encode64(cedible_binary)
      response_data = { cedible: base64_content, folio: 12345 }

      response = described_class.new(token: token, query_type: "cedible", response_data: response_data)
      expect(response.decode_cedible).to eq(cedible_binary)
    end

    it "returns nil if cedible is not available" do
      response_data = { id: 1, token: token }
      response = described_class.new(token: token, query_type: "json", response_data: response_data)
      expect(response.decode_cedible).to be_nil
    end
  end

  describe "#to_h" do
    it "converts to hash with all attributes" do
      response_data = {
        id: 1,
        token: token,
        folio: 12345,
        status: "sent"
      }

      response = described_class.new(token: token, query_type: "json", response_data: response_data)
      hash = response.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:token]).to eq(token)
      expect(hash[:query_type]).to eq("json")
      expect(hash[:document]).to be_a(Hash)
      # Folio comes from document, not directly from response
      expect(hash[:document][:folio]).to eq(12345)
    end
  end
end
