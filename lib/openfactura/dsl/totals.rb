# frozen_string_literal: true

require_relative "../errors"

module Openfactura
  module DSL
    # Totals object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Totals
      # Required fields for Totals
      REQUIRED_FIELDS = [].freeze

      attr_accessor :tax_rate, :period_amount, :amount_to_pay

      # Initialize Totals from hash with standard project keys
      # @param attributes [Hash] Hash with standard keys (tax_rate, period_amount, etc.)
      def initialize(attributes = {})
        @tax_rate = attributes[:tax_rate] || attributes["tax_rate"]
        @period_amount = attributes[:period_amount] || attributes["period_amount"]
        @amount_to_pay = attributes[:amount_to_pay] || attributes["amount_to_pay"]
      end

      # Convert to API format hash (with Spanish/CamelCase keys)
      # @return [Hash] Totals structure in API format
      def to_api_hash
        validate_required_fields!

        totals = {}
        totals[:TasaIVA] = @tax_rate.to_s if @tax_rate
        totals[:MontoPeriodo] = @period_amount if @period_amount
        totals[:VlrPagar] = @amount_to_pay if @amount_to_pay
        totals
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] Totals structure in API format
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
          # For numeric fields, check if nil or zero (zero might be valid, but nil is not)
          if value.nil?
            missing_fields << field
          elsif value.is_a?(String) && value.strip.empty?
            missing_fields << field
          end
        end

        return if missing_fields.empty?

        field_names = missing_fields.map(&:to_s).join(", ")

        raise Openfactura::ValidationError.new(
          "Totals validation failed: Missing required fields: #{field_names}",
          errors: { totals: missing_fields }
        )
      end
    end
  end
end
