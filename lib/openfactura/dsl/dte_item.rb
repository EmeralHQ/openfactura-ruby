# frozen_string_literal: true

require_relative "../errors"

module Openfactura
  module DSL
    # DTE Item (Detalle) object with standard Ruby attributes
    # Maps to API format when converted to hash
    class DteItem
      # Required fields for DteItem
      REQUIRED_FIELDS = %i[line_number name quantity price amount].freeze

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
      # @raise [ValidationError] if required fields are missing
      def to_api_hash
        validate_required_fields!

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
          # For numeric fields, check if nil (zero is valid)
          if value.nil?
            missing_fields << field
          elsif value.is_a?(String) && value.strip.empty?
            missing_fields << field
          end
        end

        return if missing_fields.empty?

        field_names = missing_fields.map do |field|
          case field
          when :line_number then "line_number (NroLinDet)"
          when :name then "name (NmbItem)"
          when :quantity then "quantity (QtyItem)"
          when :price then "price (PrcItem)"
          when :amount then "amount (MontoItem)"
          else field.to_s
          end
        end.join(", ")

        raise ValidationError.new(
          "DteItem validation failed: Missing required fields: #{field_names}",
          errors: { dte_item: missing_fields }
        )
      end
    end
  end
end
