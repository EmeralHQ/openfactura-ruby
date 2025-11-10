# frozen_string_literal: true

module Openfactura
  module DSL
    # DTE Item (Detalle) object with standard Ruby attributes
    # Maps to API format when converted to hash
    class DteItem
      attr_accessor :line_number, :name, :quantity, :price, :amount, :description, :exempt

      # Initialize DteItem from hash with standard project keys
      # @param attributes [Hash] Hash with standard keys (line_number, name, quantity, etc.)
      def initialize(attributes = {})
        @line_number = attributes[:line_number] || attributes["line_number"]
        @name = attributes[:name] || attributes["name"]
        @quantity = attributes[:quantity] || attributes["quantity"]
        @price = attributes[:price] || attributes["price"]
        @amount = attributes[:amount] || attributes["amount"]
        @description = attributes[:description] || attributes["description"]
        @exempt = attributes.key?(:exempt) ? attributes[:exempt] : (attributes.key?("exempt") ? attributes["exempt"] : nil)
      end

      # Convert to API format hash (with Spanish/CamelCase keys)
      # @return [Hash] Item structure in API format
      def to_api_hash
        item = {
          NroLinDet: @line_number,
          NmbItem: @name,
          QtyItem: @quantity,
          PrcItem: @price,
          MontoItem: @amount
        }
        item[:DscItem] = @description if @description
        item[:IndExe] = @exempt ? 1 : nil if @exempt
        item.compact
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] Item structure in API format
      def to_h
        to_api_hash
      end
    end
  end
end
