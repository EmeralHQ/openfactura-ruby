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
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }
