# frozen_string_literal: true

RSpec.describe Openfactura::DSL::Issuer do
  describe "#initialize" do
    it "initializes with standard attributes" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "VENTA AL POR MENOR",
        economic_activity_code: "479100",
        address: "ARTURO PRAT 527",
        commune: "Curicó",
        sii_branch_code: "81303347",
        phone: "+56912345678"
      )

      expect(issuer.rut).to eq("76795561-8")
      expect(issuer.business_name).to eq("HAULMER SPA")
      expect(issuer.business_activity).to eq("VENTA AL POR MENOR")
      expect(issuer.economic_activity_code).to eq("479100")
      expect(issuer.address).to eq("ARTURO PRAT 527")
      expect(issuer.commune).to eq("Curicó")
      expect(issuer.sii_branch_code).to eq("81303347")
      expect(issuer.phone).to eq("+56912345678")
    end

    it "accepts string keys" do
      issuer = described_class.new(
        "rut" => "76795561-8",
        "business_name" => "HAULMER SPA",
        "address" => "ARTURO PRAT 527"
      )

      expect(issuer.rut).to eq("76795561-8")
      expect(issuer.business_name).to eq("HAULMER SPA")
    end
  end

  describe "#to_api_hash" do
    it "converts to API format hash" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "VENTA AL POR MENOR",
        economic_activity_code: "479100",
        address: "ARTURO PRAT 527",
        commune: "Curicó",
        sii_branch_code: "81303347",
        phone: "+56912345678"
      )

      api_hash = issuer.to_api_hash

      expect(api_hash).to eq({
        RUTEmisor: "76795561-8",
        RznSoc: "HAULMER SPA",
        GiroEmis: "VENTA AL POR MENOR",
        Acteco: "479100",
        DirOrigen: "ARTURO PRAT 527",
        CmnaOrigen: "Curicó",
        CdgSIISucur: "81303347",
        Telefono: "+56912345678"
      })
    end

    it "converts economic_activity_code to string" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "VENTA AL POR MENOR",
        economic_activity_code: 479100,
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      api_hash = issuer.to_api_hash

      expect(api_hash[:Acteco]).to eq("479100")
    end

    it "excludes phone when not present" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "VENTA AL POR MENOR",
        economic_activity_code: "479100",
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      api_hash = issuer.to_api_hash

      expect(api_hash).not_to have_key(:Telefono)
    end

    it "raises ValidationError when required fields are missing" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA"
      )

      expect do
        issuer.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("Issuer validation failed")
        expect(error.message).to include("business_activity")
        expect(error.message).to include("economic_activity_code")
        expect(error.message).to include("address")
        expect(error.message).to include("commune")
        expect(error.errors[:issuer]).to be_an(Array)
      end
    end

    it "raises ValidationError when fields are empty strings" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "   ",
        economic_activity_code: "",
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      expect do
        issuer.to_api_hash
      end.to raise_error(Openfactura::ValidationError) do |error|
        expect(error.message).to include("business_activity")
        expect(error.message).to include("economic_activity_code")
      end
    end

    it "validates all required fields are present" do
      issuer = described_class.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "VENTA AL POR MENOR",
        economic_activity_code: "479100",
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      expect do
        issuer.to_api_hash
      end.not_to raise_error
    end
  end
end
