# frozen_string_literal: true

require_relative "../errors"

module Openfactura
  module DSL
    # Issuer (Emisor) object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Issuer
      # Required fields for Issuer
      REQUIRED_FIELDS = %i[rut business_name business_activity economic_activity_code address commune].freeze

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
      # @raise [ValidationError] if required fields are missing
      def to_api_hash
        validate_required_fields!

        issuer = {
          RUTEmisor: @rut,
          RznSoc: @business_name.to_s[0, 100],
          GiroEmis: @business_activity.to_s[0, 80],
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
      # @raise [ValidationError] if required fields are missing
      def to_h
        to_api_hash
      end

      private

      # Validate that all required fields are present and not empty
      # @raise [ValidationError] if any required field is missing or empty
      def validate_required_fields!
        missing_fields = []

        REQUIRED_FIELDS.each do |field|
          value = instance_variable_get("@#{field}")
          if value.nil? || (value.is_a?(String) && value.strip.empty?)
            missing_fields << field
          end
        end

        return if missing_fields.empty?

        field_names = missing_fields.map do |field|
          case field
          when :rut then "rut (RUTEmisor)"
          when :business_name then "business_name (RznSoc)"
          when :business_activity then "business_activity (GiroEmis)"
          when :economic_activity_code then "economic_activity_code (Acteco)"
          when :address then "address (DirOrigen)"
          when :commune then "commune (CmnaOrigen)"
          else field.to_s
          end
        end.join(", ")

        raise Openfactura::ValidationError.new(
          "Issuer validation failed: Missing required fields: #{field_names}",
          errors: { issuer: missing_fields }
        )
      end
    end
  end
end
