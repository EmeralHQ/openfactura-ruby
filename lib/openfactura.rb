# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.inflector.inflect("dsl" => "DSL")
loader.setup

# Explicitly require error classes to ensure they're available for rescue clauses
# This is needed because:
# 1. DocumentError is in resources/ but not namespaced under Resources
# 2. Other error classes need to be available immediately for rescue clauses
require_relative "openfactura/error"
require_relative "openfactura/resources/document_error"

# Load Railtie if Rails is available
if defined?(Rails)
  require_relative "openfactura/railtie"
end

module Openfactura
  class << self
    # Configure Open Factura SDK
    # Validation is done lazily when the API is actually used, not during configuration
    # This allows Rails to load the initializer even if API key is not yet set
    def configure
      yield(Config) if block_given?
      # Note: validate! is called lazily in Client#initialize instead of here
      # This allows configuration to be set up without immediately requiring an API key
    end

    # Get current configuration
    def config
      Config
    end

    # Get HTTP client instance
    def client
      @client ||= Client.new
    end

    # DSL accessors
    def documents
      @documents ||= DSL::Documents.new(client)
    end

    def organizations
      @organizations ||= DSL::Organizations.new(client)
    end

    # Reset client instance (useful for testing)
    def reset!
      @client = nil
      @documents = nil
      @organizations = nil
    end
  end
end