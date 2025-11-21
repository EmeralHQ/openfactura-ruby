# frozen_string_literal: true

require "dry-configurable"
require_relative "errors"

module Openfactura
  # Configuration class for Open Factura SDK
  class Config
    extend Dry::Configurable

    # API endpoint URLs
    PRODUCTION_URL = "https://api.haulmer.com"
    SANDBOX_URL = "https://dev-api.haulmer.com"

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
    end

    # Get the base URL based on environment
    def self.base_url
      return api_base_url if api_base_url

      environment == :production ? PRODUCTION_URL : SANDBOX_URL
    end

    # Validate configuration
    # This is called lazily when the Client is initialized, not during configuration
    # This allows Rails to load the initializer even if API key is not yet set
    def self.validate!
      # Ensure ValidationError is loaded
      ValidationError

      raise ValidationError, "API key is required" if api_key.nil? || api_key.to_s.strip.empty?
      raise ValidationError, "Environment must be :sandbox or :production" unless %i[sandbox production].include?(environment)
    end
  end
end
