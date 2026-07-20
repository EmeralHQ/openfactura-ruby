# frozen_string_literal: true

require "dry-configurable"
require_relative "error"

module Openfactura
  # Configuration class for Open Factura SDK
  class Config
    extend Dry::Configurable

    # API endpoint URLs
    PRODUCTION_URL = "https://api.haulmer.com"
    SANDBOX_URL = "https://dev-api.haulmer.com"

    # Single lookup table for environment → base URL, shared with Client. Frozen: it is a constant,
    # not configuration, so reading it from Client does not reintroduce shared mutable state.
    ENVIRONMENT_URLS = {
      production: PRODUCTION_URL,
      sandbox: SANDBOX_URL,
    }.freeze

    setting :api_key, default: nil
    setting :environment, default: :sandbox # :sandbox or :production
    setting :timeout, default: 30
    setting :logger, default: nil
    setting :api_base_url, default: nil # Override base URL if needed

    # Class method accessors that delegate to config instance
    class << self
      def api_key
        config.api_key
      end

      def api_key=(value)
        config.api_key = value
      end

      def environment
        config.environment
      end

      def environment=(value)
        config.environment = value
      end

      def timeout
        config.timeout
      end

      def timeout=(value)
        config.timeout = value
      end

      def logger
        config.logger
      end

      def logger=(value)
        config.logger = value
      end

      def api_base_url
        config.api_base_url
      end

      def api_base_url=(value)
        config.api_base_url = value
      end

      # Get the base URL based on environment
      def base_url
        return api_base_url if api_base_url

        ENVIRONMENT_URLS.fetch(environment, SANDBOX_URL)
      end

      # Snapshot of the configured defaults, as the keyword arguments `Client.new` expects.
      #
      # This is the ONLY bridge between global configuration and a client, and the facade calls it
      # exactly once per client — at construction. Nothing reads Config during a request, which is
      # what makes a client safe to hand to another thread or another tenant.
      #
      # @return [Hash] keyword arguments for Client.new
      def to_client_options
        {
          api_key: api_key,
          environment: environment,
          timeout: timeout,
          logger: logger,
          api_base_url: api_base_url,
        }
      end

      # Validate configuration
      # This is called lazily when the Client is initialized, not during configuration
      # This allows Rails to load the initializer even if API key is not yet set
      def validate!
        raise ValidationError, "API key is required" if api_key.nil? || api_key.to_s.strip.empty?
        raise ValidationError, "Environment must be :sandbox or :production" unless %i[sandbox production].include?(environment)
      end
    end
  end
end
