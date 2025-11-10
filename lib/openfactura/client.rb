# frozen_string_literal: true

require "httparty"
require "json"
require "net/http"
require_relative "config"
require_relative "errors"

module Openfactura
  # HTTP client for Open Factura API
  class Client
    include HTTParty

    attr_reader :config

    def initialize(config = Openfactura::Config)
      @config = config
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
      rescue AuthenticationError, NotFoundError, RateLimitError, ServerError => e
        # Re-raise our custom errors
        raise
      rescue Timeout::Error, Net::ReadTimeout => e
        raise ApiError, "Request timeout: #{e.message}"
      rescue StandardError => e
        raise ApiError, "Request failed: #{e.message}"
      end
    end

    def handle_response(response)
      case response.code
      when 200..299
        parse_response(response)
      when 401
        raise AuthenticationError
      when 404
        raise NotFoundError
      when 429
        raise RateLimitError
      when 500..599
        raise ServerError, "Server error: #{response.body}"
      else
        raise ApiError.new(
          "API request failed with status #{response.code}",
          status_code: response.code,
          response_body: response.body
        )
      end
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
