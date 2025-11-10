# frozen_string_literal: true

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
