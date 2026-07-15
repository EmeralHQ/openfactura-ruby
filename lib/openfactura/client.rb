# frozen_string_literal: true

require "httparty"
require "json"
require "net/http"
require_relative "config"
require_relative "error"

module Openfactura
  # HTTP client for Open Factura API
  class Client
    include HTTParty

    attr_reader :config

    def initialize(config = Openfactura::Config)
      @config = config
      # Validate configuration when client is actually used (lazy validation)
      config.validate! if config.respond_to?(:validate!)
      self.class.base_uri config.base_url
      self.class.default_timeout config.timeout
      self.class.headers "Content-Type" => "application/json"
      self.class.headers "apikey" => config.api_key if config.api_key
    end

    # Perform GET request
    def get(path, options = {})
      request(:get, path, options)
    end

    # Perform POST request
    def post(path, options = {})
      # Merge custom headers with default headers
      if options[:headers]
        options[:headers] = (self.class.default_options[:headers] || {}).merge(options[:headers])
      end
      # Convert body hash to JSON if it's a hash
      if options[:body].is_a?(Hash)
        options[:body] = options[:body].to_json
      end
      request(:post, path, options)
    end

    # Perform PUT request
    def put(path, options = {})
      request(:put, path, options)
    end

    # Perform DELETE request
    def delete(path, options = {})
      request(:delete, path, options)
    end

    private

    def request(method, path, options = {})
      log_request(method, path, options)

      # Merge headers properly if they exist
      if options[:headers] && self.class.default_options[:headers]
        options[:headers] = self.class.default_options[:headers].merge(options[:headers])
      end

      begin
        # HTTParty doesn't raise exceptions for non-2xx by default
        # We need to check the response code manually
        response = self.class.public_send(method, path, options)
        handle_response(response)
      rescue Openfactura::AuthenticationError, Openfactura::NotFoundError, Openfactura::RateLimitError, Openfactura::ServerError => e
        # Re-raise our custom errors
        raise
      rescue Timeout::Error, Net::ReadTimeout => e
        raise Openfactura::ApiError.new("Request timeout: #{e.message}")
      rescue StandardError => e
        raise Openfactura::ApiError.new("Request failed: #{e.message}")
      end
    end

    def handle_response(response)
      case response.code
      when 200..299
        parse_response(response)
      when 401
        error_message = extract_error_message(response.body) || "Authentication failed. Please check your API key."
        raise Openfactura::AuthenticationError.new(error_message)
      when 404
        error_message = extract_error_message(response.body) || "Resource not found"
        raise Openfactura::NotFoundError.new(error_message)
      when 429
        error_message = extract_error_message(response.body) || "Rate limit exceeded"
        raise Openfactura::RateLimitError.new(error_message)
      when 500..599
        error_message = extract_error_message(response.body) || "Server error: #{response.body}"
        raise Openfactura::ServerError.new(error_message)
      else
        # For 400 and other client errors, try to extract meaningful error message
        error_message = extract_error_message(response.body)
        base_message = if error_message
                         "API request failed with status #{response.code}: #{error_message}"
                       else
                         "API request failed with status #{response.code}"
                       end
        raise Openfactura::ApiError.new(
          base_message,
          status_code: response.code,
          response_body: response.body
        )
      end
    end

    def extract_error_message(body)
      error_data = Openfactura.parse_error_body(body)

      unless error_data
        # Body was unparseable JSON — return raw string truncated
        return body.is_a?(String) && !body.empty? ? body[0..200] : nil
      end

      error_obj = error_data[:error] || error_data["error"]
      if error_obj.is_a?(Hash)
        error_message = error_obj[:message] || error_obj["message"]
        error_code = error_obj[:code] || error_obj["code"]
        return error_code ? "[#{error_code}] #{error_message}" : error_message if error_message
      end

      error_message = error_data[:message] || error_data["message"] ||
                      error_data[:error] || error_data["error"] ||
                      error_data[:detail] || error_data["detail"]

      if error_message.is_a?(Hash)
        error_message = error_message[:message] || error_message["message"] ||
                        error_message[:error] || error_message["error"]
      end

      error_message.to_s if error_message
    end

    def parse_response(response)
      return response.body if response.body.empty?
      return response.parsed_response if response.parsed_response

      JSON.parse(response.body)
    rescue JSON::ParserError
      response.body
    end

    def log_request(method, path, options)
      return unless config.logger

      config.logger.info("[OpenFactura] #{method.upcase} #{path}")
      config.logger.debug("[OpenFactura] Options: #{options.inspect}") if options.any?
    end
  end
end
