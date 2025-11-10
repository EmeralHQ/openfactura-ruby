# frozen_string_literal: true

RSpec.describe Openfactura do
  describe ".configure" do
    it "configures the SDK" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      expect(Openfactura::Config.api_key).to eq("test-key")
      expect(Openfactura::Config.environment).to eq(:sandbox)
    end
  end

  describe ".documents" do
    it "returns documents DSL instance" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      expect(described_class.documents).to be_a(Openfactura::DSL::Documents)
    end
  end

  describe ".organizations" do
    it "returns organizations DSL instance" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      expect(described_class.organizations).to be_a(Openfactura::DSL::Organizations)
    end
  end

  describe ".reset!" do
    it "resets all instances" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      documents = described_class.documents
      described_class.reset!

      expect(described_class.documents).not_to be(documents)
    end
  end
end
