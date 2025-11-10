# frozen_string_literal: true

module Openfactura
  module DSL
    # Totals object with standard Ruby attributes
    # Maps to API format when converted to hash
    class Totals
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
      def to_api_hash
        totals = {
          MntTotal: @total_amount
        }
        totals[:MntNeto] = @net_amount if @net_amount
        totals[:IVA] = @tax_amount if @tax_amount
        totals[:MntExe] = @exempt_amount if @exempt_amount
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
    end
  end
end
