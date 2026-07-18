# frozen_string_literal: true

RSpec.describe Openfactura::Config do
  describe ".base_url" do
    it "returns sandbox URL by default" do
      Openfactura::Config.environment = :sandbox
      expect(Openfactura::Config.base_url).to eq(Openfactura::Config::SANDBOX_URL)
    end

    it "returns production URL when environment is production" do
      Openfactura::Config.environment = :production
      expect(Openfactura::Config.base_url).to eq(Openfactura::Config::PRODUCTION_URL)
    end

    it "returns custom URL when api_base_url is set" do
      Openfactura::Config.api_base_url = "https://custom.api.com"
      expect(Openfactura::Config.base_url).to eq("https://custom.api.com")
      Openfactura::Config.api_base_url = nil
    end
  end

  describe ".validate!" do
    it "raises error when API key is missing" do
      Openfactura::Config.api_key = nil
      expect { Openfactura::Config.validate! }.to raise_error(Openfactura::ValidationError, /API key is required/)
    end

    it "raises error when API key is empty" do
      Openfactura::Config.api_key = ""
      expect { Openfactura::Config.validate! }.to raise_error(Openfactura::ValidationError, /API key is required/)
    end

    it "raises error when environment is invalid" do
      Openfactura::Config.api_key = "test-key"
      Openfactura::Config.environment = :invalid
      expect { Openfactura::Config.validate! }.to raise_error(Openfactura::ValidationError, /Environment must be/)
    end

    it "passes validation with valid config" do
      Openfactura::Config.api_key = "test-key"
      Openfactura::Config.environment = :sandbox
      expect { Openfactura::Config.validate! }.not_to raise_error
    end
  end

  describe "accessors" do
    after do
      Openfactura::Config.timeout = 30
      Openfactura::Config.logger = nil
    end

    it "reads and writes the timeout" do
      Openfactura::Config.timeout = 45
      expect(Openfactura::Config.timeout).to eq(45)
    end

    it "reads and writes the logger" do
      logger = Object.new
      Openfactura::Config.logger = logger
      expect(Openfactura::Config.logger).to be(logger)
    end
  end
end
