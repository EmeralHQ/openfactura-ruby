# frozen_string_literal: true

require_relative "../../../lib/openfactura/resources/document_error"

RSpec.describe Openfactura::DocumentError do
  describe "#initialize" do
    it "initializes with error structure from API" do
      error_data = {
        error: {
          message: "Faltan datos obligatorios",
          code: "OF-01",
          details: [
            { field: "Encabezado.Emisor.RUTEmisor", issue: "Campo requerido" }
          ]
        }
      }

      error = described_class.new(error_data)

      expect(error.code).to eq("OF-01")
      expect(error.message).to eq("Faltan datos obligatorios")
      expect(error.details).to be_an(Array)
      expect(error.details.length).to eq(1)
    end

    it "can be initialized directly with error hash" do
      error_data = {
        message: "Tipo Dte no soportado",
        code: "OF-05"
      }

      error = described_class.new(error_data)

      expect(error.code).to eq("OF-05")
      expect(error.message).to eq("Tipo Dte no soportado")
    end

    it "uses error description when message is not provided" do
      error_data = {
        code: "OF-01"
      }

      error = described_class.new(error_data)

      expect(error.code).to eq("OF-01")
      expect(error.message).to eq("Faltan datos obligatorios")
    end

    it "normalizes details structure" do
      error_data = {
        error: {
          code: "OF-02",
          message: "Faltan campos obligatorios",
          details: [
            { field: "Encabezado.Receptor.RUTRecep", issue: "Campo requerido" },
            { "field" => "Detalle.0.NmbItem", "issue" => "Campo requerido" }
          ]
        }
      }

      error = described_class.new(error_data)

      expect(error.details.length).to eq(2)
      expect(error.details.first[:field]).to eq("Encabezado.Receptor.RUTRecep")
      expect(error.details.first[:issue]).to eq("Campo requerido")
      expect(error.details.last[:field]).to eq("Detalle.0.NmbItem")
    end
  end

  describe ".error_description" do
    it "returns description for valid error code" do
      expect(described_class.error_description("OF-01")).to eq("Faltan datos obligatorios")
      expect(described_class.error_description("OF-05")).to eq("Tipo Dte no soportado")
      expect(described_class.error_description("OF-23")).to include("DTE no soportado")
    end

    it "returns unknown message for invalid error code" do
      expect(described_class.error_description("OF-99")).to eq("Unknown error code: OF-99")
    end
  end

  describe "#error_description" do
    it "returns description for current error code" do
      error = described_class.new(code: "OF-01", message: "Test")
      expect(error.error_description).to eq("Faltan datos obligatorios")
    end
  end

  describe "#details_for_field" do
    it "returns details for a specific field" do
      error_data = {
        error: {
          code: "OF-10",
          message: "Validación de Campos",
          details: [
            { field: "Encabezado.Emisor.RUTEmisor", issue: "RUT inválido" },
            { field: "Encabezado.Receptor.RUTRecep", issue: "RUT inválido" },
            { field: "Encabezado.Emisor.RUTEmisor", issue: "Formato incorrecto" }
          ]
        }
      }

      error = described_class.new(error_data)

      field_errors = error.details_for_field("Encabezado.Emisor.RUTEmisor")
      expect(field_errors.length).to eq(2)
      expect(field_errors.first[:issue]).to eq("RUT inválido")
      expect(field_errors.last[:issue]).to eq("Formato incorrecto")
    end

    it "returns empty array when field has no errors" do
      error_data = {
        error: {
          code: "OF-10",
          message: "Validación de Campos",
          details: [
            { field: "Encabezado.Receptor.RUTRecep", issue: "RUT inválido" }
          ]
        }
      }

      error = described_class.new(error_data)

      field_errors = error.details_for_field("Encabezado.Emisor.RUTEmisor")
      expect(field_errors).to be_empty
    end
  end

  describe "#has_details?" do
    it "returns true when details are present" do
      error = described_class.new(
        code: "OF-01",
        message: "Test",
        details: [{ field: "test", issue: "error" }]
      )

      expect(error.has_details?).to be true
    end

    it "returns false when details are empty" do
      error = described_class.new(code: "OF-01", message: "Test", details: [])

      expect(error.has_details?).to be false
    end

    it "returns false when details are nil" do
      error = described_class.new(code: "OF-01", message: "Test")

      expect(error.has_details?).to be false
    end
  end

  describe "#error_fields" do
    it "returns unique list of fields with errors" do
      error_data = {
        error: {
          code: "OF-10",
          message: "Validación de Campos",
          details: [
            { field: "Encabezado.Emisor.RUTEmisor", issue: "Error 1" },
            { field: "Encabezado.Receptor.RUTRecep", issue: "Error 2" },
            { field: "Encabezado.Emisor.RUTEmisor", issue: "Error 3" }
          ]
        }
      }

      error = described_class.new(error_data)

      fields = error.error_fields
      expect(fields).to contain_exactly("Encabezado.Emisor.RUTEmisor", "Encabezado.Receptor.RUTRecep")
    end
  end

  describe "#to_h" do
    it "converts to hash with all attributes" do
      error = described_class.new(
        code: "OF-01",
        message: "Faltan datos obligatorios",
        details: [{ field: "test", issue: "error" }]
      )

      hash = error.to_h

      expect(hash[:code]).to eq("OF-01")
      expect(hash[:message]).to eq("Faltan datos obligatorios")
      expect(hash[:description]).to eq("Faltan datos obligatorios")
      expect(hash[:details]).to be_an(Array)
    end
  end

  describe "#to_s" do
    it "returns formatted error message with code" do
      error = described_class.new(code: "OF-01", message: "Faltan datos obligatorios")

      expect(error.to_s).to eq("[OF-01] Faltan datos obligatorios")
    end

    it "returns message only when code is nil" do
      error = described_class.new(message: "Error message")

      expect(error.to_s).to eq("Error message")
    end
  end

  describe "inheritance" do
    it "inherits from StandardError" do
      error = described_class.new(code: "OF-01", message: "Test")
      expect(error).to be_a(StandardError)
    end

    it "can be rescued as StandardError" do
      error = described_class.new(code: "OF-01", message: "Test")

      begin
        raise error
      rescue StandardError => e
        expect(e).to be_a(Openfactura::DocumentError)
        expect(e.code).to eq("OF-01")
      end
    end
  end
end
