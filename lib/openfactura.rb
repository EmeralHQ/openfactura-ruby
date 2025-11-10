# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.inflector.inflect("dsl" => "DSL")
loader.setup

# Load Railtie if Rails is available
if defined?(Rails)
  require_relative "openfactura/railtie"
end

module Openfactura
  class << self
    # Configure Open Factura SDK
    def configure
      yield(Config) if block_given?
      Config.validate!
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