# frozen_string_literal: true

require "json"

module Openfactura
  # Base error class for all Open Factura API errors
  class Error < StandardError; end

  # Parses an API response body into a hash, handling both Hash and JSON String inputs.
  # Returns nil if the body cannot be parsed or is not a recognized type.
  def self.parse_error_body(body)
    return nil unless body

    if body.is_a?(Hash)
      body
    elsif body.is_a?(String) && !body.empty?
      JSON.parse(body)
    end
  rescue JSON::ParserError
    nil
  end

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

      error_details = extract_error_details
      return "#{base_message}\n#{error_details}" if error_details

      if @response_body.is_a?(String)
        truncated = @response_body.length > 500 ? "#{@response_body[0..500]}..." : @response_body
        "#{base_message}\nResponse: #{truncated}"
      else
        base_message
      end
    end

    private

    def extract_error_details
      error_data = Openfactura.parse_error_body(@response_body)
      return nil unless error_data

      error_obj = error_data[:error] || error_data["error"]
      if error_obj.is_a?(Hash)
        error_message = error_obj[:message] || error_obj["message"]
        error_code = error_obj[:code] || error_obj["code"]
        details = error_obj[:details] || error_obj["details"] || []

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

        return error_code ? "[#{error_code}] #{error_message}" : error_message if error_message
      end

      error_message = error_data[:message] || error_data["message"] ||
                      error_data[:error] || error_data["error"] ||
                      error_data[:detail] || error_data["detail"]

      if error_message.is_a?(Hash)
        error_message = error_message[:message] || error_message["message"] ||
                        error_message[:error] || error_message["error"]
      end

      details = error_data[:details] || error_data["details"]
      if details.is_a?(Array) && details.any?
        details_str = details.map(&:to_s).join(", ")
        return "Error: #{error_message}\nDetails: #{details_str}" if error_message
        return "Details: #{details_str}"
      end

      return "Error: #{error_message}" if error_message

      if error_data.is_a?(Hash) && error_data.any?
        relevant_keys = error_data.keys.select { |k| k.to_s.match?(/error|message|detail|validation|field/i) }
        if relevant_keys.any?
          return "Error details: #{relevant_keys.map { |k| "#{k}: #{error_data[k]}" }.join(', ')}"
        end
      end

      nil
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
