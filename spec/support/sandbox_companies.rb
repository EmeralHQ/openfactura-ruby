# frozen_string_literal: true

# Load sandbox companies for testing
require_relative "../fixtures/sandbox_companies"

RSpec.configure do |config|
  # Helper method to configure Openfactura with a sandbox company
  config.define_derived_metadata do |meta|
    meta[:sandbox_company] ||= :haulmer
  end

  # Before each test that uses sandbox companies, configure with default company
  config.before(:each, :sandbox) do |example|
    company_name = example.metadata[:sandbox_company] || :haulmer
    Openfactura::SandboxCompanies.configure_with(company_name)
  end
end
