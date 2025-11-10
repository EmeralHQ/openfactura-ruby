# frozen_string_literal: true

require_relative "../resources/document"
require_relative "../resources/document_response"
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
          response = DocumentResponse.new(response_data)
          # Add idempotency_key to response
          response.idempotency_key = idempotency_key
          response
        rescue ApiError => e
          # Check if response contains error structure
          if e.response_body && (e.response_body.is_a?(Hash) || e.response_body.is_a?(String))
            error_data = e.response_body.is_a?(String) ? JSON.parse(e.response_body) : e.response_body
            if error_data[:error] || error_data["error"]
              raise DocumentError.new(error_data)
            end
          end
          raise
        end
      end

      # Get document by token
      # @param token [String] Document token
      # @return [Hash] Document data
      def find_by_token(token:)
        @client.get("/v2/dte/document/#{token}")
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
