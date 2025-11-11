# frozen_string_literal: true

require "json"

module Openfactura
  # Base error class for all Open Factura API errors
  class Error < StandardError; end

  # Error raised when API request fails
  class ApiError < Error
    attr_reader :status_code, :response_body

    def initialize(message, status_code: nil, response_body: nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end

    # Override to_s to include response body information when available
    def to_s
      base_message = super
      return base_message unless @response_body

      # Try to extract meaningful error message from response_body
      error_details = extract_error_details
      return "#{base_message}\n#{error_details}" if error_details

      # If we can't parse, show raw response (truncated if too long)
      if @response_body.is_a?(String)
        truncated = @response_body.length > 500 ? "#{@response_body[0..500]}..." : @response_body
        "#{base_message}\nResponse: #{truncated}"
      else
        base_message
      end
    end

    private

    # Extract error details from response_body
    # Handles Open Factura error format: { "error": { "message": "...", "code": "...", "details": [...] } }
    def extract_error_details
      return nil unless @response_body

      begin
        error_data = if @response_body.is_a?(Hash)
                       @response_body
                     elsif @response_body.is_a?(String)
                       JSON.parse(@response_body)
                     else
                       nil
                     end

        return nil unless error_data

        # Check for Open Factura error format: { "error": { "message": "...", "code": "...", "details": [...] } }
        error_obj = error_data[:error] || error_data["error"]
        if error_obj.is_a?(Hash)
          error_message = error_obj[:message] || error_obj["message"]
          error_code = error_obj[:code] || error_obj["code"]
          details = error_obj[:details] || error_obj["details"] || []

          # Format details array with field and issue
          if details.is_a?(Array) && details.any?
            details_str = details.map do |detail|
              field = detail[:field] || detail["field"]
              issue = detail[:issue] || detail["issue"]
              field && issue ? "#{field}: #{issue}" : detail.to_s
            end.join("\n  - ")

            message_parts = []
            message_parts << "[#{error_code}] #{error_message}" if error_code && error_message
            message_parts << error_message if error_message && !error_code
            message_parts << "Details:\n  - #{details_str}" if details_str

            return message_parts.join("\n") if message_parts.any?
          end

          # If we have message and code but no details
          if error_message
            return error_code ? "[#{error_code}] #{error_message}" : error_message
          end
        end

        # Fallback: Try common error message fields
        error_message = error_data[:message] || error_data["message"] ||
                        error_data[:error] || error_data["error"] ||
                        error_data[:detail] || error_data["detail"]

        # If error is a hash, try to get a message from it
        if error_message.is_a?(Hash)
          error_message = error_message[:message] || error_message["message"] ||
                          error_message[:error] || error_message["error"]
        end

        # If we have details array, include them
        details = error_data[:details] || error_data["details"]
        if details.is_a?(Array) && details.any?
          details_str = details.map { |d| d.is_a?(Hash) ? d.to_s : d.to_s }.join(", ")
          return "Error: #{error_message}\nDetails: #{details_str}" if error_message
          return "Details: #{details_str}"
        end

        return "Error: #{error_message}" if error_message

        # If error_data has keys that look like error fields, include them
        if error_data.is_a?(Hash) && error_data.any?
          relevant_keys = error_data.keys.select { |k| k.to_s.match?(/error|message|detail|validation|field/i) }
          if relevant_keys.any?
            relevant_info = relevant_keys.map { |k| "#{k}: #{error_data[k]}" }.join(", ")
            return "Error details: #{relevant_info}"
          end
        end

        nil
      rescue JSON::ParserError
        nil
      end
    end
  end

  # Error raised when authentication fails
  class AuthenticationError < ApiError
    def initialize(message = "Authentication failed. Please check your API key.")
      super(message, status_code: 401)
    end
  end

  # Error raised when request is invalid
  class ValidationError < Error
    attr_reader :errors

    def initialize(message, errors: {})
      super(message)
      @errors = errors
    end
  end

  # Error raised when resource is not found
  class NotFoundError < ApiError
    def initialize(message = "Resource not found")
      super(message, status_code: 404)
    end
  end

  # Error raised when rate limit is exceeded
  class RateLimitError < ApiError
    def initialize(message = "Rate limit exceeded")
      super(message, status_code: 429)
    end
  end

  # Error raised when server error occurs
  class ServerError < ApiError
    def initialize(message = "Internal server error")
      super(message, status_code: 500)
    end
  end
end
