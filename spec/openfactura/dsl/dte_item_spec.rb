# frozen_string_literal: true

require "openfactura"

RSpec.describe Openfactura::DSL::DteItem do
  describe "#initialize" do
    it "initializes with standard attributes" do
      item = described_class.new(
        line_number: 1,
        name: "Producto A",
        quantity: 2,
        price: 1000,
        description: "Descripción del producto",
        exempt: false
      )

      expect(item.line_number).to eq(1)
      expect(item.name).to eq("Producto A")
      expect(item.quantity).to eq(2)
      expect(item.price).to eq(1000)
      expect(item.description).to eq("Descripción del producto")
      expect(item.exempt).to eq(false)
    end

    it "accepts string keys" do
      item = described_class.new(
        "line_number" => 1,
        "name" => "Producto",
        "quantity" => 1,
        "price" => 2000
      )

      expect(item.line_number).to eq(1)
      expect(item.name).to eq("Producto")
    end
  end

  describe "#to_api_hash" do
    it "converts to API format hash" do
      item = described_class.new(
        line_number: 1,
        name: "Producto",
        quantity: 1,
        price: 2000
      )

      api_hash = item.to_api_hash

      expect(api_hash).to eq({
        NroLinDet: 1,
        NmbItem: "Producto",
        QtyItem: 1,
        PrcItem: 2000
      })
    end

    it "includes description when present" do
      item = described_class.new(
        line_number: 1,
        name: "Producto",
        quantity: 1,
        price: 2000,
        description: "Descripción"
      )

      api_hash = item.to_api_hash

      expect(api_hash[:DscItem]).to eq("Descripción")
    end

    it "includes IndExe when exempt is true" do
      item = described_class.new(
        line_number: 1,
        name: "Producto",
        quantity: 1,
        price: 2000,
        exempt: true
      )

      api_hash = item.to_api_hash

      expect(api_hash[:IndExe]).to eq(1)
    end

    it "excludes IndExe when exempt is false or nil" do
      item = described_class.new(
        line_number: 1,
        name: "Producto",
        quantity: 1,
        price: 2000,
        exempt: false
      )

      api_hash = item.to_api_hash

      expect(api_hash).not_to have_key(:IndExe)
    end

    it "raises ValidationError when required fields are missing" do
      item = described_class.new(
        line_number: 1,
        name: "Producto"
        # Missing: quantity, price
      )

      expect do
        item.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("DteItem validation failed")
        expect(error.message).to include("quantity")
        expect(error.message).to include("price")
        expect(error.errors[:dte_item]).to be_an(Array)
      end
    end

    it "raises ValidationError when fields are nil" do
      item = described_class.new(
        line_number: nil,
        name: "Producto",
        quantity: 1,
        price: 2000
      )

      expect do
        item.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("line_number")
      end
    end

    it "raises ValidationError when name is empty string" do
      item = described_class.new(
        line_number: 1,
        name: "",
        quantity: 1,
        price: 2000
      )

      expect do
        item.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("name")
      end
    end

    it "allows zero as valid value for numeric fields" do
      item = described_class.new(
        line_number: 1,
        name: "Producto",
        quantity: 0,
        price: 0
      )

      expect do
        api_hash = item.to_api_hash
        expect(api_hash[:QtyItem]).to eq(0)
        expect(api_hash[:PrcItem]).to eq(0)
      end.not_to raise_error
    end

    it "validates all required fields are present" do
      item = described_class.new(
        line_number: 1,
        name: "Producto",
        quantity: 1,
        price: 2000
      )

      expect do
        item.to_api_hash
      end.not_to raise_error
    end
  end
end
