# frozen_string_literal: true

RSpec.describe Openfactura::DSL::Organizations do
  let(:client) { instance_double(Openfactura::Client) }
  let(:organizations) { described_class.new(client) }

  describe "#current" do
    it "gets current organization" do
      response_data = {
        rut: "76795561-8",
        razonSocial: "HAULMER CHILE SPA",
        email: "haulmer1@haulmer.com",
        direccion: "A PRAT 545 DP 2",
        cdgSIISucur: "81303347",
        glosaDescriptiva: "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET",
        direccionRegional: "CURICÓ",
        comuna: "Curicó",
        actividades: [
          {
            giro: "PRODUCTOS Y SERVICIOS RELACIONADOS CON INTERNET",
            actividadEconomica: "VENTA AL POR MENOR POR CORREO",
            codigoActividadEconomica: "479100",
            actividadPrincipal: true
          }
        ]
      }
      expect(client).to receive(:get)
        .with("/v2/dte/organization", hash_including(query: {}))
        .and_return(response_data)

      organization = organizations.current
      expect(organization).to be_a(Openfactura::Organization)
      expect(organization.rut).to eq("76795561-8")
      expect(organization.razon_social).to eq("HAULMER CHILE SPA")
      expect(organization.email).to eq("haulmer1@haulmer.com")
    end

    it "includes extra_fields query parameter when provided" do
      response_data = { rut: "76795561-8", razonSocial: "HAULMER SPA" }
      expect(client).to receive(:get)
        .with("/v2/dte/organization", hash_including(query: { extra_fields: "logo" }))
        .and_return(response_data)

      organization = organizations.current(extra_fields: "logo")
      expect(organization).to be_a(Openfactura::Organization)
    end
  end

  describe "#current_as_issuer" do
    it "converts current organization to Issuer object" do
      response_data = {
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        direccion: "ARTURO PRAT 527",
        comuna: "Curicó",
        cdgSIISucur: "81303347",
        telefono: "+56912345678",
        glosaDescriptiva: "VENTA AL POR MENOR",
        actividades: [
          {
            giro: "VENTA AL POR MENOR",
            codigoActividadEconomica: "479100",
            actividadPrincipal: true
          }
        ]
      }

      expect(client).to receive(:get)
        .with("/v2/dte/organization", hash_including(query: {}))
        .and_return(response_data)

      issuer = organizations.current_as_issuer

      expect(issuer).to be_a(Openfactura::DSL::Issuer)
      expect(issuer.rut).to eq("76795561-8")
      expect(issuer.business_name).to eq("HAULMER SPA")
      expect(issuer.business_activity).to eq("VENTA AL POR MENOR")
      expect(issuer.economic_activity_code).to eq("479100")
      expect(issuer.address).to eq("ARTURO PRAT 527")
      expect(issuer.commune).to eq("Curicó")
      expect(issuer.sii_branch_code).to eq("81303347")
      expect(issuer.phone).to eq("+56912345678")
    end

    it "uses first activity if no primary activity" do
      response_data = {
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
      }

      expect(client).to receive(:get).and_return(response_data)

      issuer = organizations.current_as_issuer

      expect(issuer.business_activity).to eq("PRIMER GIRO")
      expect(issuer.economic_activity_code).to eq("479100")
    end

    it "uses glosa_descriptiva if no activities" do
      response_data = {
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        direccion: "ARTURO PRAT 527",
        comuna: "Curicó",
        cdgSIISucur: "81303347",
        glosaDescriptiva: "GIRO DESCRIPTIVO",
        actividades: []
      }

      expect(client).to receive(:get).and_return(response_data)

      issuer = organizations.current_as_issuer

      expect(issuer.business_activity).to eq("GIRO DESCRIPTIVO")
    end

    it "passes extra_fields to current" do
      response_data = {
        rut: "76795561-8",
        razonSocial: "HAULMER SPA",
        direccion: "ARTURO PRAT 527",
        comuna: "Curicó",
        actividades: []
      }

      expect(client).to receive(:get)
        .with("/v2/dte/organization", hash_including(query: { extra_fields: "logo" }))
        .and_return(response_data)

      organizations.current_as_issuer(extra_fields: "logo")
    end
  end

  describe "#documents" do
    it "gets organization authorized documents with available folios" do
      response_data = {
        rut: "76795561-8",
        documentos: [
          { dte: "33", disponible: 100, vencimiento: "2024-12-31" },
          { dte: "39", disponible: 50, vencimiento: "2024-12-31" }
        ]
      }
      expect(client).to receive(:get)
        .with("/v2/dte/organization/document")
        .and_return(response_data)

      result = organizations.documents
      expect(result[:rut]).to eq("76795561-8")
      expect(result[:documentos]).to be_an(Array)
      expect(result[:documentos].length).to eq(2)
      expect(result[:documentos].first[:dte]).to eq("33")
      expect(result[:documentos].first[:disponible]).to eq(100)
    end
  end
end
