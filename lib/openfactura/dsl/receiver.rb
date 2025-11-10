# frozen_string_literal: true

module Openfactura
  module DSL
    # Receiver (Receptor) object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Receiver
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
      def to_api_hash
        {
          RUTRecep: @rut,
          RznSocRecep: @business_name,
          GiroRecep: @business_activity,
          Contacto: @contact,
          DirRecep: @address,
          CmnaRecep: @commune
        }.compact
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] Receiver structure in API format
      def to_h
        to_api_hash
      end
    end
  end
end
