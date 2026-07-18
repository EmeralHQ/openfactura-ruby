# frozen_string_literal: true

require "rails/generators"
require "generators/openfactura/install_generator"
require "fileutils"

RSpec.describe Openfactura::Generators::InstallGenerator do
  destination = File.expand_path("../../tmp/generator", __dir__)

  before { FileUtils.rm_rf(destination) }
  after { FileUtils.rm_rf(destination) }

  it "creates the Open Factura initializer from the template" do
    described_class.start([], destination_root: destination)

    initializer = File.join(destination, "config/initializers/openfactura.rb")
    expect(File).to exist(initializer)
    expect(File.read(initializer)).to include("Openfactura.configure")
  end
end
