# frozen_string_literal: true

RSpec.describe Openfactura::DSL::Totals do
  describe "#initialize" do
    it "initializes with standard attributes" do
      totals = described_class.new(
        total_amount: 2380,
        net_amount: 2000,
        tax_amount: 380,
        exempt_amount: 0,
        tax_rate: "19",
        period_amount: 2380,
        amount_to_pay: 2380
      )

      expect(totals.total_amount).to eq(2380)
      expect(totals.net_amount).to eq(2000)
      expect(totals.tax_amount).to eq(380)
      expect(totals.exempt_amount).to eq(0)
      expect(totals.tax_rate).to eq("19")
      expect(totals.period_amount).to eq(2380)
      expect(totals.amount_to_pay).to eq(2380)
    end

    it "accepts string keys" do
      totals = described_class.new(
        "total_amount" => 2380,
        "net_amount" => 2000,
        "tax_amount" => 380
      )

      expect(totals.total_amount).to eq(2380)
      expect(totals.net_amount).to eq(2000)
    end
  end

  describe "#to_api_hash" do
    it "converts to API format hash" do
      totals = described_class.new(
        total_amount: 2380,
        net_amount: 2000,
        tax_amount: 380,
        tax_rate: "19"
      )

      api_hash = totals.to_api_hash

      expect(api_hash).to eq({
        MntTotal: 2380,
        MntNeto: 2000,
        IVA: 380,
        TasaIVA: "19"
      })
    end

    it "includes all optional fields when present" do
      totals = described_class.new(
        total_amount: 5000,
        net_amount: 4200,
        tax_amount: 800,
        exempt_amount: 0,
        tax_rate: "19",
        period_amount: 5000,
        amount_to_pay: 5000
      )

      api_hash = totals.to_api_hash

      expect(api_hash[:MntTotal]).to eq(5000)
      expect(api_hash[:MntNeto]).to eq(4200)
      expect(api_hash[:IVA]).to eq(800)
      expect(api_hash[:MntExe]).to eq(0)
      expect(api_hash[:TasaIVA]).to eq("19")
      expect(api_hash[:MontoPeriodo]).to eq(5000)
      expect(api_hash[:VlrPagar]).to eq(5000)
    end

    it "converts tax_rate to string" do
      totals = described_class.new(
        total_amount: 2380,
        tax_rate: 19
      )

      api_hash = totals.to_api_hash

      expect(api_hash[:TasaIVA]).to eq("19")
    end

    it "raises ValidationError when required field total_amount is missing" do
      totals = described_class.new(
        net_amount: 2000,
        tax_amount: 380
      )

      expect do
        totals.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("Totals validation failed")
        expect(error.message).to include("total_amount")
        expect(error.message).to include("MntTotal")
        expect(error.errors[:totals]).to be_an(Array)
        expect(error.errors[:totals]).to include(:total_amount)
      end
    end

    it "raises ValidationError when total_amount is nil" do
      totals = described_class.new(
        total_amount: nil,
        net_amount: 2000
      )

      expect do
        totals.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("total_amount")
      end
    end

    it "raises ValidationError when total_amount is empty string" do
      totals = described_class.new(
        total_amount: "",
        net_amount: 2000
      )

      expect do
        totals.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("total_amount")
      end
    end

    it "allows zero as valid total_amount" do
      totals = described_class.new(
        total_amount: 0
      )

      expect do
        api_hash = totals.to_api_hash
        expect(api_hash[:MntTotal]).to eq(0)
      end.not_to raise_error
    end

    it "validates all required fields are present" do
      totals = described_class.new(
        total_amount: 2380,
        net_amount: 2000,
        tax_amount: 380
      )

      expect do
        totals.to_api_hash
      end.not_to raise_error
    end
  end
end
