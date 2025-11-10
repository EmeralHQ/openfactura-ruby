# frozen_string_literal: true

module Openfactura
  # Document response model
  class DocumentResponse
    attr_accessor :token, :folio, :resolution, :xml, :pdf, :stamp, :logo, :warning, :idempotency_key

    # Initialize DocumentResponse from API response
    # @param attributes [Hash] Hash with API response fields (uppercase or snake_case)
    def initialize(attributes = {})
      # Map API response fields (uppercase) to Ruby attributes (snake_case)
      @token = attributes[:TOKEN] || attributes["TOKEN"] || attributes[:token] || attributes["token"]
      @folio = attributes[:FOLIO] || attributes["FOLIO"] || attributes[:folio] || attributes["folio"]
      @resolution = attributes[:RESOLUCION] || attributes["RESOLUCION"] || attributes[:resolucion] || attributes["resolucion"] || attributes[:resolution] || attributes["resolution"]
      @xml = attributes[:XML] || attributes["XML"] || attributes[:xml] || attributes["xml"]
      @pdf = attributes[:PDF] || attributes["PDF"] || attributes[:pdf] || attributes["pdf"]
      @stamp = attributes[:TIMBRE] || attributes["TIMBRE"] || attributes[:timbre] || attributes["timbre"] || attributes[:stamp] || attributes["stamp"]
      @logo = attributes[:LOGO] || attributes["LOGO"] || attributes[:logo] || attributes["logo"]
      @warning = attributes[:WARNING] || attributes["WARNING"] || attributes[:warning] || attributes["warning"]
      @idempotency_key = attributes[:idempotency_key] || attributes["idempotency_key"]
    end

    # Convert to hash
    # @return [Hash] Hash with all response attributes
    def to_h
      {
        token: @token,
        folio: @folio,
        resolution: @resolution,
        xml: @xml,
        pdf: @pdf,
        stamp: @stamp,
        logo: @logo,
        warning: @warning,
        idempotency_key: @idempotency_key
      }.compact
    end

    # Check if emission was successful
    def success?
      !@token.nil?
    end

    # Decode base64 XML (ISO 8859-1 encoding)
    def decode_xml
      return nil unless @xml

      require "base64"
      Base64.decode64(@xml).force_encoding("ISO-8859-1").encode("UTF-8")
    end

    # Decode base64 PDF
    def decode_pdf
      return nil unless @pdf

      require "base64"
      Base64.decode64(@pdf)
    end

    # Decode base64 stamp image
    # @return [String] Decoded stamp image binary data
    def decode_stamp
      return nil unless @stamp

      require "base64"
      Base64.decode64(@stamp)
    end

    # Alias for decode_stamp (backward compatibility)
    # @return [String] Decoded stamp image binary data
    def decode_timbre
      decode_stamp
    end

    # Decode base64 Logo image
    def decode_logo
      return nil unless @logo

      require "base64"
      Base64.decode64(@logo)
    end
  end
end
