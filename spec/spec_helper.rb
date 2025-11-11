# frozen_string_literal: true

require "bundler/setup"
require "openfactura"
require "webmock/rspec"
require "factory_bot"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # FactoryBot configuration
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  # WebMock configuration
  # Allow real HTTP connections only for integration tests
  config.before(:each) do |example|
    unless example.metadata[:integration]
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  end

  # Integration tests configuration
  config.before(:each, :integration) do
    # Allow real HTTP connections for integration tests
    WebMock.allow_net_connect!

    # Reset Openfactura configuration before each integration test
    Openfactura.reset!
  end

  config.after(:each, :integration) do
    # Reset Openfactura configuration after each integration test
    Openfactura.reset!

    # Re-enable WebMock for other tests
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end

# Helper module to check if API is available
module RSpec
  module Support
    module Helpers
      def self.api_available?
        begin
          # Temporarily allow net connections for availability check
          WebMock.allow_net_connect!
          require "net/http"
          require "uri"
          uri = URI.parse("https://dev-api.haulmer.com")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 5
          http.read_timeout = 5
          http.head("/")
          true
        rescue StandardError
          false
        ensure
          # Re-enable WebMock blocking after check
          WebMock.disable_net_connect!(allow_localhost: true)
        end
      end
    end
  end
end

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }
