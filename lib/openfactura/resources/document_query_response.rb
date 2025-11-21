# frozen_string_literal: true

require_relative "document"

module Openfactura
  # Document query response model for find_by_token
  # Handles different response types: json, status, pdf, xml, cedible
  class DocumentQueryResponse
    attr_accessor :token, :query_type, :document, :status, :pdf, :xml, :cedible, :folio

    # Initialize DocumentQueryResponse from API response
    # @param token [String] Document token
    # @param query_type [String] Type of query: "json", "status", "pdf", "xml", "cedible"
    # @param response_data [Hash, String] API response data
    def initialize(token:, query_type:, response_data:)
      @token = token
      @query_type = query_type.to_s.downcase

      case @query_type
      when "json"
        # JSON returns full document data
        @document = map_response_to_document(response_data)
        @folio = @document.folio if @document
      when "status"
        # Status returns a string: "Aceptado", "Pendiente", "Rechazado", "Aceptado con Reparo"
        @status = response_data.is_a?(String) ? response_data : response_data.to_s
        @document = Openfactura::Document.new(status: @status, dte_id: token)
      when "pdf", "xml", "cedible"
        # These return base64 encoded content in a hash with the key matching the value
        # Response format: { "pdf": "base64...", "folio": 600625 }
        if response_data.is_a?(Hash)
          # Extract the base64 content (value can be symbol or string key)
          content = response_data[@query_type.to_sym] || response_data[@query_type] || response_data[@query_type.upcase]
          @folio = response_data[:folio] || response_data["folio"] || response_data[:FOLIO] || response_data["FOLIO"]

          case @query_type
          when "pdf"
            @pdf = content
          when "xml"
            @xml = content
          when "cedible"
            @cedible = content
          end
        else
          # If response is not a hash, treat as direct content
          case @query_type
          when "pdf"
            @pdf = response_data
          when "xml"
            @xml = response_data
          when "cedible"
            @cedible = response_data
          end
        end
      end
    end

    # Get the content based on query type
    # @return [Document, String, nil] Content based on query type
    def content
      case @query_type
      when "json"
        @document
      when "status"
        @status
      when "pdf"
        @pdf
      when "xml"
        @xml
      when "cedible"
        @cedible
      else
        nil
      end
    end

    # Check if response has document data (for json query)
    # @return [Boolean] True if document is available
    def has_document?
      !@document.nil?
    end

    # Get document (for json and status queries)
    # @return [Document, nil] Document object if available
    def document
      @document
    end

    # Decode base64 PDF content
    # @return [String, nil] Decoded PDF binary data
    def decode_pdf
      return nil unless @pdf

      require "base64"
      Base64.decode64(@pdf)
    end

    # Decode base64 XML content (ISO 8859-1 encoding)
    # @return [String, nil] Decoded XML string
    def decode_xml
      return nil unless @xml

      require "base64"
      Base64.decode64(@xml).force_encoding("ISO-8859-1").encode("UTF-8")
    end

    # Decode base64 Cedible content
    # @return [String, nil] Decoded Cedible binary data
    def decode_cedible
      return nil unless @cedible

      require "base64"
      Base64.decode64(@cedible)
    end

    # Convert to hash
    # @return [Hash] Hash with all response attributes
    def to_h
      hash = {
        token: @token,
        query_type: @query_type
      }

      hash[:document] = @document.to_h if @document
      hash[:status] = @status if @status
      hash[:pdf] = @pdf if @pdf
      hash[:xml] = @xml if @xml
      hash[:cedible] = @cedible if @cedible
      hash[:folio] = @folio if @folio

      hash
    end

    private

    # Map API response to Document object
    # @param response_data [Hash] API response data
    # @return [Document] Document object with mapped attributes
    def map_response_to_document(response_data)
      # Handle both symbol and string keys
      data = response_data.is_a?(Hash) ? response_data : {}

      # Map common fields from API response to Document attributes
      attributes = {
        id: data[:id] || data["id"],
        dte_id: data[:dte_id] || data["dte_id"] || data[:token] || data["token"] || @token,
        type: data[:type] || data["type"] || data[:tipo_dte] || data["tipo_dte"],
        status: data[:status] || data["status"] || data[:estado] || data["estado"],
        folio: data[:folio] || data["folio"],
        issuer_rut: data[:issuer_rut] || data["issuer_rut"] || data[:rut_emisor] || data["rut_emisor"],
        receiver_rut: data[:receiver_rut] || data["receiver_rut"] || data[:rut_receptor] || data["rut_receptor"],
        amount: data[:amount] || data["amount"] || data[:monto_total] || data["monto_total"],
        tax_amount: data[:tax_amount] || data["tax_amount"] || data[:iva] || data["iva"],
        created_at: data[:created_at] || data["created_at"] || data[:fecha_emision] || data["fecha_emision"],
        updated_at: data[:updated_at] || data["updated_at"]
      }

      Openfactura::Document.new(attributes)
    end
  end
end
