# frozen_string_literal: true

require "base64"
require_relative "../../../lib/openfactura/resources/document_response"

RSpec.describe Openfactura::DocumentResponse do
  describe "#initialize" do
    it "initializes with API response attributes" do
      response = described_class.new(
        TOKEN: "test-token-123",
        FOLIO: 12345,
        RESOLUCION: { fecha: "2024-01-15", numero: "0" },
        XML: "base64xml",
        PDF: "base64pdf",
        TIMBRE: "base64timbre",
        LOGO: "base64logo",
        WARNING: "Warning message"
      )

      expect(response.token).to eq("test-token-123")
      expect(response.folio).to eq(12345)
      expect(response.resolution).to eq({ fecha: "2024-01-15", numero: "0" })
      expect(response.xml).to eq("base64xml")
      expect(response.pdf).to eq("base64pdf")
      expect(response.stamp).to eq("base64timbre")
      expect(response.logo).to eq("base64logo")
      expect(response.warning).to eq("Warning message")
    end

    it "accepts snake_case attributes" do
      response = described_class.new(
        token: "test-token",
        folio: 12345,
        resolution: { fecha: "2024-01-15" },
        xml: "base64xml",
        pdf: "base64pdf",
        stamp: "base64stamp",
        logo: "base64logo"
      )

      expect(response.token).to eq("test-token")
      expect(response.folio).to eq(12345)
      expect(response.resolution).to eq({ fecha: "2024-01-15" })
    end

    it "accepts idempotency_key" do
      response = described_class.new(
        token: "test-token",
        idempotency_key: "custom-key-123"
      )

      expect(response.idempotency_key).to eq("custom-key-123")
    end
  end

  describe "#success?" do
    it "returns true when token is present" do
      response = described_class.new(token: "test-token")
      expect(response.success?).to be true
    end

    it "returns false when token is nil" do
      response = described_class.new(folio: 12345)
      expect(response.success?).to be false
    end
  end

  describe "#to_h" do
    it "converts to hash with all attributes" do
      response = described_class.new(
        token: "test-token",
        folio: 12345,
        resolution: { fecha: "2024-01-15" },
        xml: "base64xml",
        pdf: "base64pdf",
        stamp: "base64stamp",
        logo: "base64logo",
        warning: "Warning",
        idempotency_key: "key-123"
      )

      hash = response.to_h

      expect(hash).to eq({
        token: "test-token",
        folio: 12345,
        resolution: { fecha: "2024-01-15" },
        xml: "base64xml",
        pdf: "base64pdf",
        stamp: "base64stamp",
        logo: "base64logo",
        warning: "Warning",
        idempotency_key: "key-123"
      })
    end

    it "excludes nil values" do
      response = described_class.new(token: "test-token")

      hash = response.to_h

      expect(hash).not_to have_key(:xml)
      expect(hash).not_to have_key(:pdf)
    end
  end

  describe "#decode_xml" do
    it "decodes base64 XML and handles ISO-8859-1 encoding" do
      xml_content = "<?xml version='1.0' encoding='ISO-8859-1'?><root>Test</root>".dup
      base64_xml = Base64.encode64(xml_content.force_encoding("ISO-8859-1"))

      response = described_class.new(xml: base64_xml)

      decoded = response.decode_xml
      expect(decoded).to include("Test")
    end

    it "returns nil when xml is not present" do
      response = described_class.new(token: "test-token")
      expect(response.decode_xml).to be_nil
    end
  end

  describe "#decode_pdf" do
    it "decodes base64 PDF" do
      pdf_content = "PDF binary content"
      base64_pdf = Base64.encode64(pdf_content)

      response = described_class.new(pdf: base64_pdf)

      decoded = response.decode_pdf
      expect(decoded).to eq(pdf_content)
    end

    it "returns nil when pdf is not present" do
      response = described_class.new(token: "test-token")
      expect(response.decode_pdf).to be_nil
    end
  end

  describe "#decode_stamp" do
    it "decodes base64 stamp image" do
      stamp_content = "stamp binary content"
      base64_stamp = Base64.encode64(stamp_content)

      response = described_class.new(stamp: base64_stamp)

      decoded = response.decode_stamp
      expect(decoded).to eq(stamp_content)
    end

    it "returns nil when stamp is not present" do
      response = described_class.new(token: "test-token")
      expect(response.decode_stamp).to be_nil
    end
  end

  describe "#decode_timbre" do
    it "is an alias for decode_stamp" do
      stamp_content = "stamp binary content"
      base64_stamp = Base64.encode64(stamp_content)

      response = described_class.new(stamp: base64_stamp)

      expect(response.decode_timbre).to eq(response.decode_stamp)
    end
  end

  describe "#decode_logo" do
    it "decodes base64 logo image" do
      logo_content = "logo binary content"
      base64_logo = Base64.encode64(logo_content)

      response = described_class.new(logo: base64_logo)

      decoded = response.decode_logo
      expect(decoded).to eq(logo_content)
    end

    it "returns nil when logo is not present" do
      response = described_class.new(token: "test-token")
      expect(response.decode_logo).to be_nil
    end
  end
end
