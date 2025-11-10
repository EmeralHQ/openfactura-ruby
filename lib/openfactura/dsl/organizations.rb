# frozen_string_literal: true

require_relative "../resources/organization"
require_relative "issuer"

module Openfactura
  module DSL
    # DSL for organization operations
    class Organizations
      def initialize(client)
        @client = client
      end

      # Get current organization (based on API key)
      # @param extra_fields [String] Additional fields to include (e.g., "logo")
      # @return [Organization] Organization object with contributor information
      def current(extra_fields: nil)
        query_params = {}
        query_params[:extra_fields] = extra_fields if extra_fields
        response = @client.get("/v2/dte/organization", query: query_params)
        Organization.new(response)
      end

      # Get current organization as Issuer object
      # @param extra_fields [String] Additional fields to include (e.g., "logo")
      # @return [Issuer] Issuer object with all data needed to create a DTE
      def current_as_issuer(extra_fields: nil)
        organization = current(extra_fields: extra_fields)
        build_issuer_from_organization(organization)
      end

      # Get organization authorized documents with available folios
      # @return [Hash] Hash with rut and documentos array containing DTE types and available folios
      def documents
        response = @client.get("/v2/dte/organization/document")
        response
      end

      private

      # Build Issuer object from Organization data
      # @param organization [Organization] Organization object
      # @return [Issuer] Issuer object
      def build_issuer_from_organization(organization)
        raise ArgumentError, "organization must be an Organization object" unless organization.is_a?(Organization)

        primary_activity = organization.primary_activity || {}
        business_activity = primary_activity[:giro] || primary_activity["giro"] || organization.glosa_descriptiva
        economic_activity_code = primary_activity[:codigoActividadEconomica] || primary_activity["codigoActividadEconomica"] ||
                                 (organization.actividades.first && (organization.actividades.first[:codigoActividadEconomica] || organization.actividades.first["codigoActividadEconomica"]))

        Issuer.new(
          rut: organization.rut,
          business_name: organization.razon_social,
          business_activity: business_activity,
          economic_activity_code: economic_activity_code,
          address: organization.direccion,
          commune: organization.comuna,
          sii_branch_code: organization.cdg_sii_sucur,
          phone: organization.telefono
        )
      end
    end
  end
end
