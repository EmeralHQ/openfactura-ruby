# frozen_string_literal: true

require "httparty"
require "json"
require "net/http"
require "openssl"
require "socket"
require_relative "config"
require_relative "error"

module Openfactura
  # HTTP client for Open Factura API
  class Client
    include HTTParty

    # Transport-level failures, the only exceptions this client translates into ApiError. Everything
    # else propagates untouched: an ApiError from handle_response keeps its status_code and
    # response_body, and a bug in the gem (NoMethodError, TypeError…) surfaces as itself instead of
    # being disguised as an API failure with its backtrace lost (see #12).
    #
    # Do NOT add a `rescue StandardError` fallback here. That is exactly what this fix removes.
    TIMEOUT_ERRORS = [
      Timeout::Error, # Net::OpenTimeout and Net::ReadTimeout descend from this
      Net::ReadTimeout,
      Net::OpenTimeout,
    ].freeze

    CONNECTION_ERRORS = [
      SocketError,             # DNS resolution failure
      OpenSSL::SSL::SSLError,  # TLS handshake/certificate failure
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      EOFError,                # connection closed mid-response
      HTTParty::Error,         # e.g. RedirectionTooDeep
    ].freeze

    attr_reader :config

    def initialize(config = Openfactura::Config)
      @config = config
      # Validate configuration when client is actually used (lazy validation)
      config.validate! if config.respond_to?(:validate!)
      # Per-instance, immutable connection options. Nothing is written to class-level HTTParty
      # state, so two clients built with different keys never clobber each other (see #6).
      @base_uri = config.base_url
      headers = { "Content-Type" => "application/json" }
      headers["apikey"] = config.api_key if config.api_key
      @default_options = { timeout: config.timeout, headers: headers.freeze }.freeze
    end

    # Perform GET request
    def get(path, options = {})
      request(:get, path, options)
    end

    # Perform POST request
    def post(path, options = {})
      options = options.dup
      # Convert body hash to JSON if it's a hash. Header merging happens centrally in `request`.
      options[:body] = options[:body].to_json if options[:body].is_a?(Hash)
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
      merged = build_options(options)
      log_request(method, path, merged)

      begin
        # HTTParty doesn't raise exceptions for non-2xx by default; the status is checked in
        # handle_response. Dispatch through HTTParty's module functions with fully-formed per-request
        # options so no shared class-level state is read or written (see #6).
        response = HTTParty.public_send(method, "#{@base_uri}#{path}", merged)
        handle_response(response)
      rescue *TIMEOUT_ERRORS => e
        raise Openfactura::ApiError.new("Request timeout: #{e.message}")
      rescue *CONNECTION_ERRORS => e
        raise Openfactura::ApiError.new("Connection failed: #{e.message}")
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

    # Merge per-call options over the instance defaults without mutating either the caller's
    # options or the frozen instance defaults. Headers are merged so the apikey/Content-Type
    # defaults survive alongside per-call headers (e.g. Idempotency-Key).
    def build_options(options)
      headers = @default_options[:headers].merge(options[:headers] || {})
      @default_options.merge(options).merge(headers: headers)
    end

    # Header names whose value must never reach the logs (case-insensitive).
    SENSITIVE_HEADERS = ["apikey"].freeze

    def log_request(method, path, options)
      logger = config.logger
      return unless logger

      logger.info("[OpenFactura] #{method.upcase} #{path}")
      # Never log the request body (it carries the DTE with real RUTs and amounts) and redact the
      # apikey. Only method, path and the non-sensitive headers (e.g. Idempotency-Key) are logged.
      logger.debug("[OpenFactura] headers: #{redact_headers(options[:headers])}")
    end

    def redact_headers(headers)
      return "{}" unless headers.is_a?(Hash)

      headers.to_h do |key, value|
        [key, SENSITIVE_HEADERS.include?(key.to_s.downcase) ? "[FILTERED]" : value]
      end.inspect
    end
  end
end
