# frozen_string_literal: true

RSpec.describe Openfactura::DSL::Totals do
  describe "#initialize" do
    it "initializes with standard attributes" do
      totals = described_class.new(
        tax_rate: "19",
        period_amount: 2380,
        amount_to_pay: 2380
      )

      expect(totals.tax_rate).to eq("19")
      expect(totals.period_amount).to eq(2380)
      expect(totals.amount_to_pay).to eq(2380)
    end

    it "accepts string keys" do
      totals = described_class.new(
        "tax_rate" => "19"
      )

      expect(totals.tax_rate).to eq("19")
    end
  end

  describe "#to_api_hash" do
    it "converts to API format hash" do
      totals = described_class.new(
        tax_rate: "19"
      )

      api_hash = totals.to_api_hash

      expect(api_hash).to eq({
        TasaIVA: "19"
      })
    end

    it "includes all optional fields when present" do
      totals = described_class.new(
        tax_rate: "19",
        period_amount: 5000,
        amount_to_pay: 5000
      )

      api_hash = totals.to_api_hash

      expect(api_hash[:TasaIVA]).to eq("19")
      expect(api_hash[:MontoPeriodo]).to eq(5000)
      expect(api_hash[:VlrPagar]).to eq(5000)
    end

    it "converts tax_rate to string" do
      totals = described_class.new(
        tax_rate: 19
      )

      api_hash = totals.to_api_hash

      expect(api_hash[:TasaIVA]).to eq("19")
    end

    it "works with empty totals" do
      totals = described_class.new({})

      expect do
        api_hash = totals.to_api_hash
        expect(api_hash).to eq({})
      end.not_to raise_error
    end
  end
end
