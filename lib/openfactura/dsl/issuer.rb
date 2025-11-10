# frozen_string_literal: true

module Openfactura
  module DSL
    # Issuer (Emisor) object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Issuer
      attr_accessor :rut, :business_name, :business_activity, :economic_activity_code, :address, :commune, :sii_branch_code, :phone

      # Initialize Issuer from hash with standard project keys
      # @param attributes [Hash] Hash with standard keys (rut, business_name, address, etc.)
      def initialize(attributes = {})
        @rut = attributes[:rut] || attributes["rut"]
        @business_name = attributes[:business_name] || attributes["business_name"]
        @business_activity = attributes[:business_activity] || attributes["business_activity"]
        @economic_activity_code = attributes[:economic_activity_code] || attributes["economic_activity_code"]
        @address = attributes[:address] || attributes["address"]
        @commune = attributes[:commune] || attributes["commune"]
        @sii_branch_code = attributes[:sii_branch_code] || attributes["sii_branch_code"]
        @phone = attributes[:phone] || attributes["phone"]
      end

      # Convert to API format hash (with Spanish/CamelCase keys)
      # @return [Hash] Issuer structure in API format
      def to_api_hash
        issuer = {
          RUTEmisor: @rut,
          RznSoc: @business_name,
          GiroEmis: @business_activity,
          Acteco: @economic_activity_code.to_s,
          DirOrigen: @address,
          CmnaOrigen: @commune,
          CdgSIISucur: @sii_branch_code
        }
        issuer[:Telefono] = @phone if @phone
        issuer.compact
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] Issuer structure in API format
      def to_h
        to_api_hash
      end
    end
  end
end
