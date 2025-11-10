# frozen_string_literal: true

require "date"
require_relative "receiver"
require_relative "dte_item"
require_relative "totals"
require_relative "issuer"

module Openfactura
  module DSL
    # DTE (Electronic Tax Document) object with standard Ruby keys
    # Maps to API format when converted to hash
    class Dte
      # Valid DTE types
      VALID_DTE_TYPES = [
        33,  # Factura Electrónica
        34,  # Factura No Afecta o Exenta Electrónica
        43,  # Liquidación-Factura Electrónica
        46,  # Factura de Compra Electrónica
        52,  # Guía de Despacho Electrónica
        56,  # Nota de Débito Electrónica
        61,  # Nota de Crédito Electrónica
        110, # Factura de Exportación
        111, # Nota de Débito de Exportación
        112  # Nota de Crédito de Exportación
      ].freeze

      # Valid date range for emission_date
      MIN_EMISSION_DATE = Date.new(2003, 4, 1).freeze
      MAX_EMISSION_DATE = Date.new(2050, 12, 31).freeze

      attr_reader :type
      attr_reader :emission_date
      attr_accessor :folio, :purchase_transaction_type, :sale_transaction_type, :payment_form
      attr_accessor :receiver, :items, :totals, :issuer

      # Setter for emission_date with validation
      # @param value [String, Date] Emission date in YYYY-MM-DD format
      # @raise [ArgumentError] if date format or range is invalid
      def emission_date=(value)
        validated_date = validate_emission_date!(value)
        @emission_date = validated_date
      end

      # Setter for type with validation
      # @param value [Integer] DTE type
      # @raise [ArgumentError] if type is not valid
      def type=(value)
        raise ArgumentError, "type is required" if value.nil?
        validate_dte_type!(value)
        @type = value
      end

      # Initialize DTE from hash with standard project keys
      # @param attributes [Hash] Hash with standard keys (type, receiver, items, totals, etc.)
      #   - receiver can be a Receiver object or a Hash
      #   - items can be an Array of DteItem objects or Hashes
      #   - totals can be a Totals object or a Hash
      #   - issuer can be an Issuer object or a Hash
      # @raise [ArgumentError] if type is not a valid DTE type
      def initialize(attributes = {})
        type_value = attributes[:type] || attributes["type"]
        raise ArgumentError, "type is required" if type_value.nil?
        validate_dte_type!(type_value)
        @type = type_value
        @folio = attributes[:folio] || attributes["folio"] || 0

        # Validate and set emission_date (defaults to today if not provided)
        emission_date_value = attributes[:emission_date] || attributes["emission_date"] || Date.today.strftime("%Y-%m-%d")
        @emission_date = validate_emission_date!(emission_date_value)
        @purchase_transaction_type = attributes[:purchase_transaction_type] || attributes["purchase_transaction_type"]
        @sale_transaction_type = attributes[:sale_transaction_type] || attributes["sale_transaction_type"]
        @payment_form = attributes[:payment_form] || attributes["payment_form"]

        # Convert receiver to Receiver object if it's a hash
        receiver_data = attributes[:receiver] || attributes["receiver"] || {}
        @receiver = receiver_data.is_a?(Receiver) ? receiver_data : Receiver.new(receiver_data)

        # Convert items to DteItem objects if they're hashes
        items_data = attributes[:items] || attributes["items"] || []
        @items = items_data.map do |item|
          item.is_a?(DteItem) ? item : DteItem.new(item)
        end

        # Convert totals to Totals object if it's a hash
        totals_data = attributes[:totals] || attributes["totals"] || {}
        @totals = totals_data.is_a?(Totals) ? totals_data : Totals.new(totals_data)

        # Convert issuer to Issuer object if it's a hash
        issuer_data = attributes[:issuer] || attributes["issuer"]
        @issuer = issuer_data.is_a?(Issuer) ? issuer_data : (issuer_data ? Issuer.new(issuer_data) : nil)
      end

      # Convert to API format hash (with Spanish/CamelCase keys)
      # @return [Hash] DTE structure in API format
      def to_api_hash
        id_doc = {
          TipoDTE: @type,
          Folio: @folio,
          FchEmis: @emission_date
        }
        id_doc[:TpoTranCompra] = @purchase_transaction_type if @purchase_transaction_type
        id_doc[:TpoTranVenta] = @sale_transaction_type if @sale_transaction_type
        id_doc[:FmaPago] = @payment_form if @payment_form

        dte = {
          Encabezado: {
            IdDoc: id_doc,
            Receptor: @receiver.to_api_hash,
            Totales: @totals.to_api_hash
          },
          Detalle: @items.map(&:to_api_hash)
        }

        # Add Emisor if provided
        dte[:Encabezado][:Emisor] = @issuer.to_api_hash if @issuer

        dte
      end

      # Alias for to_api_hash for compatibility
      # @return [Hash] DTE structure in API format
      def to_h
        to_api_hash
      end

      private

      # Validate DTE type
      # @param type [Integer] DTE type to validate
      # @raise [ArgumentError] if type is not valid
      def validate_dte_type!(type)
        unless VALID_DTE_TYPES.include?(type)
          raise ArgumentError, "Invalid DTE type: #{type}. Valid types are: #{VALID_DTE_TYPES.join(', ')}"
        end
      end

      # Validate emission date format and range
      # @param date_value [String, Date] Date to validate
      # @return [String] Validated date in YYYY-MM-DD format
      # @raise [ArgumentError] if date format or range is invalid
      def validate_emission_date!(date_value)
        # Convert Date object to string if needed
        date_string = date_value.is_a?(Date) ? date_value.strftime("%Y-%m-%d") : date_value.to_s

        # Validate format YYYY-MM-DD (10 characters)
        unless date_string.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          raise ArgumentError, "Invalid emission_date format: #{date_string}. Expected format: YYYY-MM-DD"
        end

        # Parse and validate it's a valid date
        begin
          parsed_date = Date.parse(date_string)
        rescue ArgumentError => e
          raise ArgumentError, "Invalid emission_date: #{date_string}. #{e.message}"
        end

        # Validate date range: 2003-04-01 to 2050-12-31
        if parsed_date < MIN_EMISSION_DATE
          raise ArgumentError, "Invalid emission_date: #{date_string}. Date must be >= #{MIN_EMISSION_DATE.strftime('%Y-%m-%d')}"
        end

        if parsed_date > MAX_EMISSION_DATE
          raise ArgumentError, "Invalid emission_date: #{date_string}. Date must be <= #{MAX_EMISSION_DATE.strftime('%Y-%m-%d')}"
        end

        date_string
      end
    end
  end
end
