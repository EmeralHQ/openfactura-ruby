# frozen_string_literal: true

RSpec.describe Openfactura::SandboxCompanies do
  describe ".[]" do
    it "returns Haulmer company data" do
      company = described_class[:haulmer]
      expect(company[:apikey]).to eq("928e15a2d14d4a6292345f04960f4bd3")
      expect(company[:rut_emisor]).to eq("76795561-8")
      expect(company[:razon_social]).to eq("HAULMER SPA")
    end

    it "returns Hosty company data" do
      company = described_class[:hosty]
      expect(company[:apikey]).to eq("41eb78998d444dbaa4922c410ef14057")
      expect(company[:rut_emisor]).to eq("76430498-5")
      expect(company[:razon_social]).to eq("HOSTY SPA")
    end

    it "raises error for unknown company" do
      expect { described_class[:unknown] }.to raise_error(ArgumentError, /Unknown company/)
    end
  end

  describe ".configure_with" do
    it "configures Openfactura with Haulmer API key" do
      company = described_class.configure_with(:haulmer)
      expect(Openfactura::Config.api_key).to eq("928e15a2d14d4a6292345f04960f4bd3")
      expect(Openfactura::Config.environment).to eq(:sandbox)
      expect(company[:razon_social]).to eq("HAULMER SPA")
    end

    it "configures Openfactura with Hosty API key" do
      company = described_class.configure_with(:hosty)
      expect(Openfactura::Config.api_key).to eq("41eb78998d444dbaa4922c410ef14057")
      expect(Openfactura::Config.environment).to eq(:sandbox)
      expect(company[:razon_social]).to eq("HOSTY SPA")
    end

    it "allows setting custom environment" do
      described_class.configure_with(:haulmer, environment: :production)
      expect(Openfactura::Config.environment).to eq(:production)
    end
  end

  describe ".all" do
    it "returns all available companies" do
      companies = described_class.all
      expect(companies).to have_key(:haulmer)
      expect(companies).to have_key(:hosty)
      expect(companies[:haulmer][:razon_social]).to eq("HAULMER SPA")
      expect(companies[:hosty][:razon_social]).to eq("HOSTY SPA")
    end
  end

  describe "issuer data" do
    it "provides issuer data for Haulmer" do
      issuer = described_class[:haulmer][:issuer]
      expect(issuer[:rut]).to eq("76795561-8")
      expect(issuer[:razon_social]).to eq("HAULMER SPA")
      expect(issuer[:codigo_sii_sucursal]).to eq("81303347")
    end

    it "provides issuer data for Hosty" do
      issuer = described_class[:hosty][:issuer]
      expect(issuer[:rut]).to eq("76430498-5")
      expect(issuer[:razon_social]).to eq("HOSTY SPA")
      expect(issuer[:codigo_sii_sucursal]).to eq("79457965")
    end
  end
end
