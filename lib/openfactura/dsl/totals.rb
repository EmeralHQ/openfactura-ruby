# frozen_string_literal: true

require_relative "../error"

module Openfactura
  module DSL
    # Totals object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Totals
      # Required fields for Totals
      REQUIRED_FIELDS = %i[total_amount net_amount tax_amount ].freeze

      attr_accessor :total_amount, :net_amount, :tax_amount, :exempt_amount, :tax_rate, :period_amount, :amount_to_pay

      # Initialize Totals from hash with standard project keys
      # @param attributes [Hash] Hash with standard keys (total_amount, net_amount, etc.)
      def initialize(attributes = {})
        @total_amount = attributes[:total_amount] || attributes["total_amount"]
        @net_amount = attributes[:net_amount] || attributes["net_amount"]
        @tax_amount = attributes[:tax_amount] || attributes["tax_amount"]
        @exempt_amount = attributes[:exempt_amount] || attributes["exempt_amount"]
        @tax_rate = attributes[:tax_rate] || attributes["tax_rate"]
        @period_amount = attributes[:period_amount] || attributes["period_amount"]
        @amount_to_pay = attributes[:amount_to_pay] || attributes["amount_to_pay"]
      end

      # Convert to API format hash (with Spanish/CamelCase keys)
      # @return [Hash] Totals structure in API format
      # @raise [ValidationError] if required fields are missing
      def to_api_hash
        validate_required_fields!

        totals = {
          MntTotal: @total_amount.to_i
        }
        totals[:MntNeto] = @net_amount.to_i if @net_amount
        totals[:IVA] = @tax_amount.to_i if @tax_amount
        totals[:MntExe] = @exempt_amount.to_i if @exempt_amount
        totals[:TasaIVA] = @tax_rate.to_f.round(2) if @tax_rate
        totals[:MontoPeriodo] = @period_amount.to_i if @period_amount
        totals[:VlrPagar] = @amount_to_pay.to_i if @amount_to_pay
        totals
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] Totals structure in API format
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
          # For numeric fields, check if nil or zero (zero might be valid, but nil is not)
          if value.nil?
            missing_fields << field
          elsif value.is_a?(String) && value.strip.empty?
            missing_fields << field
          end
        end

        return if missing_fields.empty?

        field_names = missing_fields.map do |field|
          case field
          when :total_amount then "total_amount (MntTotal)"
          else field.to_s
          end
        end.join(", ")

        raise Openfactura::ValidationError.new(
          "Totals validation failed: Missing required fields: #{field_names}",
          errors: { totals: missing_fields }
        )
      end
    end
  end
end
