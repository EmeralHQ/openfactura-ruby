# frozen_string_literal: true

require "json"
require_relative "../../../lib/openfactura/resources/organization"

RSpec.describe Openfactura::Organization do
  describe "#initialize" do
    it "initializes with API response attributes (camelCase)" do
      org = described_class.new(
        rut: "76795561-8",
        razonSocial: "HAULMER CHILE SPA",
        email: "haulmer1@haulmer.com",
        telefono: "+56912345678",
        direccion: "A PRAT 545 DP 2",
        cdgSIISucur: "81303347",
        glosaDescriptiva: "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET",
        direccionRegional: "CURICÓ",
        comuna: "Curicó",
        ciudad: "Curicó",
        nombreFantasia: "Haulmer Pruebas",
        web: "www.openfactura.cl",
        resolucion: { fecha: "2022-09-07", numero: "0" },
        actividades: [
          {
            giro: "PRODUCTOS Y SERVICIOS",
            actividadEconomica: "VENTA AL POR MENOR",
            codigoActividadEconomica: "479100",
            actividadPrincipal: true
          }
        ]
      )

      expect(org.rut).to eq("76795561-8")
      expect(org.razon_social).to eq("HAULMER CHILE SPA")
      expect(org.email).to eq("haulmer1@haulmer.com")
      expect(org.cdg_sii_sucur).to eq("81303347")
      expect(org.glosa_descriptiva).to eq("PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET")
      expect(org.actividades).to be_an(Array)
      expect(org.actividades.length).to eq(1)
    end

    it "accepts snake_case attributes as fallback" do
      org = described_class.new(
        rut: "76795561-8",
        razon_social: "HAULMER SPA",
        cdg_sii_sucur: "81303347"
      )

      expect(org.rut).to eq("76795561-8")
      expect(org.razon_social).to eq("HAULMER SPA")
      expect(org.cdg_sii_sucur).to eq("81303347")
    end
  end

  describe "#to_h" do
    it "converts organization to hash" do
      org = described_class.new(
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        email: "test@example.com"
      )

      hash = org.to_h
      expect(hash[:rut]).to eq("76795561-8")
      expect(hash[:razon_social]).to eq("HAULMER SPA")
      expect(hash[:email]).to eq("test@example.com")
    end

    it "excludes nil values" do
      org = described_class.new(rut: "76795561-8")
      hash = org.to_h
      expect(hash).not_to have_key(:email) if org.email.nil?
      expect(hash).not_to have_key(:telefono) if org.telefono.nil?
    end
  end

  describe "#to_issuer_h" do
    it "converts to DTE issuer format using primary activity" do
      org = described_class.new(
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        direccion: "ARTURO PRAT 527",
        comuna: "Curicó",
        cdgSIISucur: "81303347",
        actividades: [
          {
            giro: "VENTA AL POR MENOR",
            codigoActividadEconomica: "479100",
            actividadPrincipal: true
          },
          {
            giro: "OTRO GIRO",
            codigoActividadEconomica: "620200",
            actividadPrincipal: false
          }
        ]
      )

      issuer_hash = org.to_issuer_h
      expect(issuer_hash[:rut]).to eq("76795561-8")
      expect(issuer_hash[:razon_social]).to eq("HAULMER SPA")
      expect(issuer_hash[:giro]).to eq("VENTA AL POR MENOR")
      expect(issuer_hash[:actividad_economica]).to eq("479100")
      expect(issuer_hash[:codigo_sii_sucursal]).to eq("81303347")
    end

    it "uses first activity if no primary activity is found" do
      org = described_class.new(
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        direccion: "ARTURO PRAT 527",
        comuna: "Curicó",
        cdgSIISucur: "81303347",
        actividades: [
          {
            giro: "PRIMER GIRO",
            codigoActividadEconomica: "479100",
            actividadPrincipal: false
          }
        ]
      )

      issuer_hash = org.to_issuer_h
      expect(issuer_hash[:giro]).to eq("PRIMER GIRO")
    end

    it "uses glosa_descriptiva if no activities available" do
      org = described_class.new(
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        glosaDescriptiva: "GIRO DESCRIPTIVO",
        direccion: "ARTURO PRAT 527",
        comuna: "Curicó",
        cdgSIISucur: "81303347",
        actividades: []
      )

      issuer_hash = org.to_issuer_h
      expect(issuer_hash[:giro]).to eq("GIRO DESCRIPTIVO")
    end
  end

  describe "#primary_activity" do
    it "returns the primary activity" do
      org = described_class.new(
        actividades: [
          { actividadPrincipal: false, giro: "GIRO 1" },
          { actividadPrincipal: true, giro: "GIRO PRINCIPAL" },
          { actividadPrincipal: false, giro: "GIRO 2" }
        ]
      )

      primary = org.primary_activity
      expect(primary[:giro]).to eq("GIRO PRINCIPAL")
    end

    it "returns first activity if no primary is found" do
      org = described_class.new(
        actividades: [
          { actividadPrincipal: false, giro: "GIRO 1" },
          { actividadPrincipal: false, giro: "GIRO 2" }
        ]
      )

      primary = org.primary_activity
      expect(primary[:giro]).to eq("GIRO 1")
    end
  end

  describe "#to_json" do
    it "converts organization to JSON" do
      org = described_class.new(rut: "76795561-8", razon_social: "HAULMER SPA")
      json = org.to_json
      expect(json).to be_a(String)
      expect(JSON.parse(json)["rut"]).to eq("76795561-8")
    end
  end
end
