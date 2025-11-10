# frozen_string_literal: true

# Sandbox Companies for Development Testing
# These are test companies provided by Open Factura for sandbox environment

module Openfactura
  module SandboxCompanies
    HAULMER = {
      apikey: "928e15a2d14d4a6292345f04960f4bd3",
      rut_emisor: "76795561-8",
      razon_social: "HAULMER SPA",
      giro_emisor: "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
      actividad_economica: 479100,
      direccion_origen: "ARTURO PRAT 527   CURICO",
      comuna_origen: "Curicó",
      codigo_sii_sucursal: "81303347",
      issuer: {
        rut: "76795561-8",
        razon_social: "HAULMER SPA",
        giro: "VENTA AL POR MENOR EN EMPRESAS DE VENTA A DISTANCIA VÍA INTERNET; COMERCIO ELEC",
        actividad_economica: 479100,
        direccion: "ARTURO PRAT 527   CURICO",
        comuna: "Curicó",
        codigo_sii_sucursal: "81303347"
      }
    }.freeze

    HOSTY = {
      apikey: "41eb78998d444dbaa4922c410ef14057",
      rut_emisor: "76430498-5",
      razon_social: "HOSTY SPA",
      giro_emisor: "EMPRESAS DE SERVICIOS INTEGRALES DE INFORMÁTICA",
      actividad_economica: 620200,
      direccion_origen: "ARTURO PRAT 527 3 pis OF 1",
      comuna_origen: "Curicó",
      codigo_sii_sucursal: "79457965",
      issuer: {
        rut: "76430498-5",
        razon_social: "HOSTY SPA",
        giro: "EMPRESAS DE SERVICIOS INTEGRALES DE INFORMÁTICA",
        actividad_economica: 620200,
        direccion: "ARTURO PRAT 527 3 pis OF 1",
        comuna: "Curicó",
        codigo_sii_sucursal: "79457965"
      }
    }.freeze

    # Helper method to get company by name
    def self.[](name)
      case name.to_s.downcase
      when "haulmer"
        HAULMER
      when "hosty"
        HOSTY
      else
        raise ArgumentError, "Unknown company: #{name}. Available: haulmer, hosty"
      end
    end

    # Helper method to configure Openfactura with a company's API key
    def self.configure_with(company_name, environment: :sandbox)
      company = self[company_name]
      Openfactura.configure do |config|
        config.api_key = company[:apikey]
        config.environment = environment
      end
      company
    end

    # Get all available companies
    def self.all
      {
        haulmer: HAULMER,
        hosty: HOSTY
      }
    end
  end
end
