# frozen_string_literal: true

RSpec.describe Openfactura::Client do
  let(:config) { Openfactura::Config }
  let(:client) { described_class.new(config) }

  before do
    config.api_key = "test-api-key"
    config.environment = :sandbox
    config.api_base_url = nil
  end

  describe "#get" do
    it "makes a GET request" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .with(headers: { "apikey" => "test-api-key", "Content-Type" => "application/json" })
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      response = client.get("/v1/test")
      expect(response["success"] || response[:success]).to be true
    end

    it "raises AuthenticationError on 401" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 401, body: "", headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::AuthenticationError)
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, "#{config.base_url}/v1/test")
        .to_return(status: 404, body: "", headers: { "Content-Type" => "application/json" })

      expect { client.get("/v1/test") }.to raise_error(Openfactura::NotFoundError)
    end
  end

  describe "#post" do
    it "makes a POST request with body" do
      stub_request(:post, "#{config.base_url}/v1/test")
        .with(
          headers: { "apikey" => "test-api-key", "Content-Type" => "application/json" },
          body: "{\"name\":\"test\"}"
        )
        .to_return(status: 200, body: '{"id": 1}', headers: { "Content-Type" => "application/json" })

      response = client.post("/v1/test", body: { name: "test" })
      expect(response["id"] || response[:id]).to eq(1)
    end
  end
end
