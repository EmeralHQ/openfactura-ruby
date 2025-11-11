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
                raise DocumentError.new(error_data)
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
      # @return [Document, String] Returns Document object for "json" and "status", String (base64) for "pdf"/"xml"/"cedible"
      # @raise [ArgumentError] if value is not one of the valid options
      # @example Get document JSON data
      #   document = Openfactura.documents.find_by_token(token: "abc123", value: "json")
      #   puts document.status
      #   puts document.folio
      # @example Get document status
      #   document = Openfactura.documents.find_by_token(token: "abc123", value: "status")
      #   puts document.status # "Aceptado", "Pendiente", "Rechazado", or "Aceptado con Reparo"
      # @example Get PDF content (base64)
      #   pdf_base64 = Openfactura.documents.find_by_token(token: "abc123", value: "pdf")
      #   # Returns base64 encoded PDF string
      def find_by_token(token:, value: "json")
        valid_values = %w[status xml json pdf cedible]
        value_normalized = value.to_s.downcase
        unless valid_values.include?(value_normalized)
          raise ArgumentError, "value must be one of: #{valid_values.join(', ')}"
        end

        path = "/v2/dte/document/#{token}/#{value_normalized}"
        response_data = @client.get(path)

        # Handle response based on value type
        case value_normalized
        when "status"
          # Status returns a string: "Aceptado", "Pendiente", "Rechazado", "Aceptado con Reparo"
          # Create Document object with status
          Document.new(status: response_data, dte_id: token)
        when "json"
          # JSON returns full document data - map to Document object
          map_response_to_document(response_data)
        when "pdf", "xml", "cedible"
          # These return base64 encoded content in a hash with the key matching the value
          # Response format: { "pdf": "base64...", "folio": 600625 }
          # Extract the base64 content (value can be symbol or string key)
          if response_data.is_a?(Hash)
            # Try to get the content by the value key (pdf, xml, or cedible)
            content = response_data[value_normalized.to_sym] || response_data[value_normalized]
            # If not found, return the entire response (shouldn't happen but handle gracefully)
            content || response_data
          else
            # If response is not a hash, return as-is
            response_data
          end
        else
          # Fallback: return raw response
          response_data
        end
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
          dte_id: data[:dte_id] || data["dte_id"] || data[:token] || data["token"],
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

        Document.new(attributes)
      end

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
