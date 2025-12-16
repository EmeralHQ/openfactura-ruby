# frozen_string_literal: true

require_relative "../error"

module Openfactura
  module DSL
    # Receiver (Receptor) object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Receiver
      # Required fields for Receiver
      REQUIRED_FIELDS = %i[rut business_name business_activity contact address commune].freeze

      attr_accessor :rut, :business_name, :business_activity, :contact, :address, :commune

      # Initialize Receiver from hash with standard project keys
      # @param attributes [Hash] Hash with standard keys (rut, business_name, address, etc.)
      def initialize(attributes = {})
        @rut = attributes[:rut] || attributes["rut"]
        @business_name = attributes[:business_name] || attributes["business_name"]
        @business_activity = attributes[:business_activity] || attributes["business_activity"]
        @contact = attributes[:contact] || attributes["contact"]
        @address = attributes[:address] || attributes["address"]
        @commune = attributes[:commune] || attributes["commune"]
      end

      # Convert to API format hash (with Spanish/CamelCase keys)
      # @return [Hash] Receiver structure in API format
      # @raise [ValidationError] if required fields are missing
      def to_api_hash
        validate_required_fields!

        {
          RUTRecep: @rut,
          RznSocRecep: @business_name.to_s[0, 100],
          GiroRecep: @business_activity.to_s[0, 40],
          Contacto: @contact,
          DirRecep: @address,
          CmnaRecep: @commune
        }
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] Receiver structure in API format
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
          when :rut then "rut (RUTRecep)"
          when :business_name then "business_name (RznSocRecep)"
          when :business_activity then "business_activity (GiroRecep)"
          when :contact then "contact (Contacto)"
          when :address then "address (DirRecep)"
          when :commune then "commune (CmnaRecep)"
          else field.to_s
          end
        end.join(", ")

        raise Openfactura::ValidationError.new(
          "Receiver validation failed: Missing required fields: #{field_names}",
          errors: { receiver: missing_fields }
        )
      end
    end
  end
end
