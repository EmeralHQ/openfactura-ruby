# frozen_string_literal: true

require "rails/railtie"
require "openfactura/railtie"

RSpec.describe Openfactura::Railtie do
  it "is a Rails::Railtie so Rails auto-loads the gem's integration" do
    expect(described_class.ancestors).to include(Rails::Railtie)
  end

  it "registers the install generator" do
    expect(described_class.respond_to?(:generators)).to be true
  end
end
