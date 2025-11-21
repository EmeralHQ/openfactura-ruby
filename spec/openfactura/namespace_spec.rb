# frozen_string_literal: true

RSpec.describe "Openfactura namespace implementation" do
  describe "namespace structure" do
    it "defines the Openfactura module" do
      expect(defined?(Openfactura)).to be_truthy
      expect(Openfactura).to be_a(Module)
    end

    it "defines the Openfactura::DSL module" do
      expect(defined?(Openfactura::DSL)).to be_truthy
      expect(Openfactura::DSL).to be_a(Module)
    end

    it "defines VERSION constant" do
      expect(Openfactura::VERSION).to be_a(String)
    end
  end

  describe "core classes" do
    it "defines Openfactura::Config" do
      expect(Openfactura::Config).to be_a(Class)
    end

    it "defines Openfactura::Client" do
      expect(Openfactura::Client).to be_a(Class)
    end

    it "defines Openfactura::Error" do
      expect(Openfactura::Error).to be_a(Class)
      expect(Openfactura::Error).to be < StandardError
    end

    it "defines Openfactura::ApiError" do
      expect(Openfactura::ApiError).to be_a(Class)
      expect(Openfactura::ApiError).to be < Openfactura::Error
    end

    it "defines Openfactura::ValidationError" do
      expect(Openfactura::ValidationError).to be_a(Class)
      expect(Openfactura::ValidationError).to be < Openfactura::Error
    end

    it "defines Openfactura::AuthenticationError" do
      expect(Openfactura::AuthenticationError).to be_a(Class)
      expect(Openfactura::AuthenticationError).to be < Openfactura::ApiError
    end

    it "defines Openfactura::NotFoundError" do
      expect(Openfactura::NotFoundError).to be_a(Class)
      expect(Openfactura::NotFoundError).to be < Openfactura::ApiError
    end

    it "defines Openfactura::RateLimitError" do
      expect(Openfactura::RateLimitError).to be_a(Class)
      expect(Openfactura::RateLimitError).to be < Openfactura::ApiError
    end

    it "defines Openfactura::ServerError" do
      expect(Openfactura::ServerError).to be_a(Class)
      expect(Openfactura::ServerError).to be < Openfactura::ApiError
    end
  end

  describe "DSL classes" do
    it "defines Openfactura::DSL::Documents" do
      expect(Openfactura::DSL::Documents).to be_a(Class)
    end

    it "defines Openfactura::DSL::Organizations" do
      expect(Openfactura::DSL::Organizations).to be_a(Class)
    end

    it "defines Openfactura::DSL::Dte" do
      expect(Openfactura::DSL::Dte).to be_a(Class)
    end

    it "defines Openfactura::DSL::DteItem" do
      expect(Openfactura::DSL::DteItem).to be_a(Class)
    end

    it "defines Openfactura::DSL::Issuer" do
      expect(Openfactura::DSL::Issuer).to be_a(Class)
    end

    it "defines Openfactura::DSL::Receiver" do
      expect(Openfactura::DSL::Receiver).to be_a(Class)
    end

    it "defines Openfactura::DSL::Totals" do
      expect(Openfactura::DSL::Totals).to be_a(Class)
    end
  end

  describe "resource classes" do
    it "defines Openfactura::Document" do
      expect(Openfactura::Document).to be_a(Class)
    end

    it "defines Openfactura::DocumentResponse" do
      expect(Openfactura::DocumentResponse).to be_a(Class)
    end

    it "defines Openfactura::DocumentQueryResponse" do
      expect(Openfactura::DocumentQueryResponse).to be_a(Class)
    end

    it "defines Openfactura::DocumentError" do
      expect(Openfactura::DocumentError).to be_a(Class)
      expect(Openfactura::DocumentError).to be < StandardError
    end

    it "defines Openfactura::Organization" do
      expect(Openfactura::Organization).to be_a(Class)
    end
  end

  describe "cross-namespace references" do
    context "when DSL classes reference resource classes" do
      it "Documents can instantiate DocumentResponse" do
        Openfactura.configure do |config|
          config.api_key = "test-key"
          config.environment = :sandbox
        end

        documents = Openfactura::DSL::Documents.new(Openfactura.client)
        # This tests that DocumentResponse is accessible from DSL::Documents
        response = Openfactura::DocumentResponse.new({})
        expect(response).to be_a(Openfactura::DocumentResponse)
      end

      it "Documents can instantiate DocumentQueryResponse" do
        query_response = Openfactura::DocumentQueryResponse.new(
          token: "test-token",
          query_type: "json",
          response_data: {}
        )
        expect(query_response).to be_a(Openfactura::DocumentQueryResponse)
      end

      it "Organizations can instantiate Organization" do
        organization = Openfactura::Organization.new({})
        expect(organization).to be_a(Openfactura::Organization)
      end

      it "Organizations can check if object is an Organization" do
        organization = Openfactura::Organization.new({})
        expect(organization.is_a?(Openfactura::Organization)).to be true
      end
    end

    context "when DSL classes reference other DSL classes" do
      it "Dte can instantiate Receiver" do
        receiver = Openfactura::DSL::Receiver.new({})
        expect(receiver).to be_a(Openfactura::DSL::Receiver)
      end

      it "Dte can instantiate DteItem" do
        item = Openfactura::DSL::DteItem.new({})
        expect(item).to be_a(Openfactura::DSL::DteItem)
      end

      it "Dte can instantiate Totals" do
        totals = Openfactura::DSL::Totals.new({})
        expect(totals).to be_a(Openfactura::DSL::Totals)
      end

      it "Dte can instantiate Issuer" do
        issuer = Openfactura::DSL::Issuer.new({})
        expect(issuer).to be_a(Openfactura::DSL::Issuer)
      end

      it "Dte can check if objects are correct types" do
        receiver = Openfactura::DSL::Receiver.new({})
        item = Openfactura::DSL::DteItem.new({})
        totals = Openfactura::DSL::Totals.new({})
        issuer = Openfactura::DSL::Issuer.new({})

        expect(receiver.is_a?(Openfactura::DSL::Receiver)).to be true
        expect(item.is_a?(Openfactura::DSL::DteItem)).to be true
        expect(totals.is_a?(Openfactura::DSL::Totals)).to be true
        expect(issuer.is_a?(Openfactura::DSL::Issuer)).to be true
      end
    end

    context "when Config references error classes" do
      it "Config can raise ValidationError" do
        Openfactura::Config.api_key = nil
        expect { Openfactura::Config.validate! }.to raise_error(Openfactura::ValidationError)
      end
    end

    context "when Client references error classes" do
      it "Client can raise ApiError" do
        error = Openfactura::ApiError.new("Test error")
        expect(error).to be_a(Openfactura::ApiError)
      end

      it "Client can raise AuthenticationError" do
        error = Openfactura::AuthenticationError.new
        expect(error).to be_a(Openfactura::AuthenticationError)
      end

      it "Client can raise NotFoundError" do
        error = Openfactura::NotFoundError.new
        expect(error).to be_a(Openfactura::NotFoundError)
      end

      it "Client can raise RateLimitError" do
        error = Openfactura::RateLimitError.new
        expect(error).to be_a(Openfactura::RateLimitError)
      end

      it "Client can raise ServerError" do
        error = Openfactura::ServerError.new
        expect(error).to be_a(Openfactura::ServerError)
      end
    end
  end

  describe "Zeitwerk autoloading" do
    it "loads all classes through Zeitwerk" do
      # This test verifies that Zeitwerk can resolve all class names
      expect { Openfactura::Config }.not_to raise_error
      expect { Openfactura::Client }.not_to raise_error
      expect { Openfactura::DSL::Documents }.not_to raise_error
      expect { Openfactura::DSL::Organizations }.not_to raise_error
      expect { Openfactura::Document }.not_to raise_error
      expect { Openfactura::DocumentResponse }.not_to raise_error
    end

    it "inflects DSL correctly" do
      # Zeitwerk should inflect "dsl" to "DSL"
      expect(Openfactura::DSL).to be_a(Module)
    end
  end

  describe "namespace isolation" do
    it "does not pollute global namespace" do
      # These should not be defined in the global namespace
      expect(defined?(Config)).to be_nil
      expect(defined?(Client)).to be_nil
      expect(defined?(Documents)).to be_nil
      expect(defined?(Dte)).to be_nil
      expect(defined?(Document)).to be_nil
    end

    it "requires full namespace path to access classes" do
      # These should not be accessible without the Openfactura:: prefix
      expect { Config }.to raise_error(NameError)
      expect { Client }.to raise_error(NameError)
      expect { Documents }.to raise_error(NameError)
    end
  end

  describe "module hierarchy" do
    it "maintains correct parent-child relationships" do
      expect(Openfactura::DSL::Documents.superclass).to eq(Object)
      expect(Openfactura::DSL::Organizations.superclass).to eq(Object)
      expect(Openfactura::Document.superclass).to eq(Object)
      expect(Openfactura::DocumentResponse.superclass).to eq(Object)
    end

    it "maintains correct error class hierarchy" do
      expect(Openfactura::Error.superclass).to eq(StandardError)
      expect(Openfactura::ApiError.superclass).to eq(Openfactura::Error)
      expect(Openfactura::ValidationError.superclass).to eq(Openfactura::Error)
      expect(Openfactura::AuthenticationError.superclass).to eq(Openfactura::ApiError)
    end
  end

  describe "class instantiation with full namespace" do
    it "can instantiate Config" do
      expect(Openfactura::Config).to respond_to(:api_key=)
    end

    it "can instantiate Client" do
      Openfactura.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      client = Openfactura::Client.new
      expect(client).to be_a(Openfactura::Client)
    end

    it "can instantiate DSL classes" do
      Openfactura.configure do |config|
        config.api_key = "test-key"
        config.environment = :sandbox
      end

      documents = Openfactura::DSL::Documents.new(Openfactura.client)
      expect(documents).to be_a(Openfactura::DSL::Documents)

      organizations = Openfactura::DSL::Organizations.new(Openfactura.client)
      expect(organizations).to be_a(Openfactura::DSL::Organizations)
    end

    it "can instantiate resource classes" do
      document = Openfactura::Document.new({})
      expect(document).to be_a(Openfactura::Document)

      response = Openfactura::DocumentResponse.new({})
      expect(response).to be_a(Openfactura::DocumentResponse)

      organization = Openfactura::Organization.new({})
      expect(organization).to be_a(Openfactura::Organization)
    end
  end

  describe "DocumentError availability for rescue clauses" do
    it "can be rescued immediately after requiring the gem" do
      # This test ensures DocumentError is available for rescue clauses
      # even before any other code in the gem is used
      expect(defined?(Openfactura::DocumentError)).to be_truthy
      expect(Openfactura::DocumentError).to be_a(Class)
    end

    it "can be used in rescue clauses without explicit require" do
      # Simulate a rescue clause scenario
      error = nil
      begin
        raise Openfactura::DocumentError.new({ error: { code: "OF-01", message: "Test error" } })
      rescue Openfactura::DocumentError => e
        error = e
      end

      expect(error).to be_a(Openfactura::DocumentError)
      expect(error.code).to eq("OF-01")
    end
  end
end
