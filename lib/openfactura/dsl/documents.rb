# frozen_string_literal: true

require_relative "../resources/document"
require_relative "../resources/document_response"
require_relative "../resources/document_query_response"
require_relative "../resources/document_error"
require_relative "../resources/organization"
require_relative "dte"
require_relative "issuer"
require "date"
require "json"
require "securerandom"

module Openfactura
  module DSL
    # DSL for electronic document operations
    class Documents
      def initialize(client)
        @client = client
      end

      # Emit a DTE (Electronic Tax Document)
      # @param dte [Dte] Dte object to emit
      # @param issuer [Issuer] Issuer object (required)
      # @param response [Array] Array of response types to include (e.g., ["PDF", "XML", "FOLIO"])
      # @param custom [Hash] Custom fields (informationNote, paymentNote)
      # @param iva_exceptional [Array] IVA exceptional types (e.g., ["ARTESANO"])
      # @param send_email [Hash] Email sending configuration
      # @param idempotency_key [String] Idempotency key for safe retries. If nil, will be auto-generated
      # @return [DocumentResponse] Response with token, folio, PDF, XML, idempotency_key, etc.
      def emit(dte:, issuer:, response: ["TOKEN"], custom: nil, iva_exceptional: nil, send_email: nil, idempotency_key: nil)
        raise ArgumentError, "dte must be a Dte object" unless dte.is_a?(Dte)
        raise ArgumentError, "issuer must be an Issuer object" unless issuer.is_a?(Issuer)

        # Generate idempotency_key if not provided
        idempotency_key ||= generate_idempotency_key

        # Build request body
        body = build_emission_body(dte: dte, response: response, custom: custom, iva_exceptional: iva_exceptional, send_email: send_email, issuer: issuer)

        # Build headers with idempotency_key (always present)
        headers = {
          "Idempotency-Key" => idempotency_key
        }

        # Make request
        # HTTParty automatically converts hash to JSON, so we pass the hash directly
        begin
          response_data = @client.post("/v2/dte/document", body: body, headers: headers)
          response = Openfactura::DocumentResponse.new(response_data)
          # Add idempotency_key to response
          response.idempotency_key = idempotency_key
          response
        rescue Openfactura::ApiError => e
          # Check if response contains Open Factura error format: { "error": { "message": "...", "code": "...", "details": [...] } }
          if e.response_body
            begin
              error_data = if e.response_body.is_a?(Hash)
                             e.response_body
                           elsif e.response_body.is_a?(String)
                             JSON.parse(e.response_body)
                           else
                             nil
                           end

              # If error_data has an 'error' key with the Open Factura format, convert to DocumentError
              if error_data && (error_data[:error] || error_data["error"])
                raise Openfactura::DocumentError.new(error_data)
              end
            rescue JSON::ParserError
              # If JSON parsing fails, just raise the original ApiError (which will include the body)
            end
          end
          # Re-raise ApiError (it now includes response_body in the message via to_s override)
          raise
        end
      end

      # Get document by token
      # @param token [String] Document token (required)
      # @param value [String] Value to retrieve: "status", "xml", "json", "pdf", or "cedible" (default: "json")
      # @return [DocumentQueryResponse] Returns DocumentQueryResponse object with content based on query type
      # @raise [ArgumentError] if value is not one of the valid options
      # @example Get document JSON data
      #   response = Openfactura.documents.find_by_token(token: "abc123", value: "json")
      #   puts response.document.status
      #   puts response.document.folio
      # @example Get document status
      #   response = Openfactura.documents.find_by_token(token: "abc123", value: "status")
      #   puts response.status # "Aceptado", "Pendiente", "Rechazado", or "Aceptado con Reparo"
      # @example Get PDF content (base64)
      #   response = Openfactura.documents.find_by_token(token: "abc123", value: "pdf")
      #   pdf_binary = response.decode_pdf # Decoded PDF binary data
      #   pdf_base64 = response.pdf # Base64 encoded PDF string
      def find_by_token(token:, value: "json")
        raise ArgumentError, "token is required" if token.nil? || token.empty?

        valid_values = %w[status xml json pdf cedible]
        value_normalized = value.to_s.downcase
        unless valid_values.include?(value_normalized)
          raise ArgumentError, "value must be one of: #{valid_values.join(', ')}"
        end

        path = "/v2/dte/document/#{token}/#{value_normalized}"
        response_data = @client.get(path)

        Openfactura::DocumentQueryResponse.new(
          token: token,
          query_type: value_normalized,
          response_data: response_data
        )
      end

      private

      # Build emission request body
      def build_emission_body(dte:, response:, custom:, iva_exceptional:, send_email:, issuer:)
        # Set issuer in dte if provided and not already set
        dte.issuer = issuer if issuer && dte.issuer.nil?

        # Convert Dte object to API hash format
        dte_hash = dte.to_api_hash

        # Ensure dte is a hash with symbol keys
        dte_hash = dte_hash.transform_keys(&:to_sym) if dte_hash.keys.any? { |k| k.is_a?(String) }

        # Recursively convert nested hash keys to symbols
        dte_hash = deep_symbolize_keys(dte_hash)

        body = {
          dte: dte_hash,
          response: response
        }

        body[:custom] = custom if custom
        body[:ivaExceptional] = iva_exceptional if iva_exceptional
        body[:sendEmail] = send_email if send_email

        body
      end

      # Recursively convert hash keys to symbols
      def deep_symbolize_keys(hash)
        return hash unless hash.is_a?(Hash)

        hash.each_with_object({}) do |(key, value), result|
          new_key = key.is_a?(String) ? key.to_sym : key
          new_value = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
          new_value = value.map { |v| v.is_a?(Hash) ? deep_symbolize_keys(v) : v } if value.is_a?(Array)
          result[new_key] = new_value
        end
      end

      # Generate a unique idempotency key
      # @return [String] UUID v4 string
      def generate_idempotency_key
        SecureRandom.uuid
      end
    end
  end
end
