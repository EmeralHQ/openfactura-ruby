# frozen_string_literal: true

require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.collapse("#{__dir__}/openfactura/resources")
loader.inflector.inflect("dsl" => "DSL")
loader.setup

require_relative "openfactura/error"

# Load Railtie if Rails is available
if defined?(Rails)
  require_relative "openfactura/railtie"
end

# Facade over a single default client, for the common single-tenant case:
#
#   Openfactura.configure { |c| c.api_key = ENV["OF_KEY"] }
#   Openfactura.documents.emit(dte: dte, issuer: issuer)
#
# Applications serving several contributors should build clients directly instead — each one is
# self-contained and independent, so there is no global state to collide over:
#
#   client = Openfactura::Client.new(api_key: tenant.api_key, environment: :production)
#   client.documents.emit(dte: dte, issuer: issuer)
module Openfactura
  @mutex = Mutex.new

  class << self
    # Configure the default client. Validation stays lazy — it happens when the client is actually
    # built — so a Rails initializer can load before the API key is known.
    #
    # Reconfiguring discards the current default client so the new settings take effect. Before, the
    # client was memoized on first use and every later `configure` was silently ignored.
    def configure
      yield(Config) if block_given?
      reset!
    end

    # Get current configuration
    def config
      Config
    end

    # The default client, built from Config on first use.
    # @raise [Openfactura::ValidationError] if the api_key has not been configured
    def client
      # Double-checked under a mutex: without it two threads racing the first call would each build
      # a client and one would be silently discarded.
      return @client if @client

      @mutex.synchronize { @client ||= Client.new(**Config.to_client_options) }
    end

    # DSL accessors, delegated to the default client.
    def documents
      client.documents
    end

    def organizations
      client.organizations
    end

    # Discard the default client so the next call rebuilds it from the current Config.
    def reset!
      @mutex.synchronize { @client = nil }
    end
  end
end
