# frozen_string_literal: true

RSpec.describe "Openfactura error handling" do
  describe "Openfactura.parse_error_body" do
    it "returns nil for a nil body" do
      expect(Openfactura.parse_error_body(nil)).to be_nil
    end

    it "returns the hash unchanged when the body is already a Hash" do
      body = { "error" => "boom" }
      expect(Openfactura.parse_error_body(body)).to eq(body)
    end

    it "parses a JSON string body into a hash" do
      expect(Openfactura.parse_error_body('{"code":"OF-01"}')).to eq({ "code" => "OF-01" })
    end

    it "returns nil for a malformed JSON string" do
      expect(Openfactura.parse_error_body("{not valid json")).to be_nil
    end

    it "returns nil for an empty string" do
      expect(Openfactura.parse_error_body("")).to be_nil
    end

    it "returns nil for an unrecognized type" do
      expect(Openfactura.parse_error_body(12_345)).to be_nil
    end
  end

  describe Openfactura::ApiError do
    it "returns just the base message when there is no response body" do
      error = described_class.new("Something failed")
      expect(error.to_s).to eq("Something failed")
    end

    it "appends a truncated raw response when the body is an unparseable string" do
      error = described_class.new("Failed", response_body: "plain text error")
      expect(error.to_s).to eq("Failed\nResponse: plain text error")
    end

    it "truncates a very long string response body" do
      error = described_class.new("Failed", response_body: "x" * 600)
      expect(error.to_s).to include("Failed\nResponse:")
      expect(error.to_s).to end_with("...")
    end

    it "falls back to the base message when the body is neither string nor parseable" do
      error = described_class.new("Failed", response_body: 42)
      expect(error.to_s).to eq("Failed")
    end

    it "formats an error object with a code but no details" do
      error = described_class.new("Failed", response_body: { error: { message: "Bad key", code: "OF-05" } })
      expect(error.to_s).to include("[OF-05] Bad key")
    end

    it "formats a top-level message key without an error object" do
      error = described_class.new("Failed", response_body: { "message" => "Top level problem" })
      expect(error.to_s).to include("Error: Top level problem")
    end

    it "unwraps a nested message hash" do
      error = described_class.new("Failed", response_body: { "message" => { "message" => "Deep problem" } })
      expect(error.to_s).to include("Error: Deep problem")
    end

    it "scans for relevant keys when there is no conventional message field" do
      error = described_class.new("Failed", response_body: { "validationErrors" => "field X is invalid" })
      expect(error.to_s).to include("Error details:")
      expect(error.to_s).to include("validationErrors: field X is invalid")
    end

    # Regression guard for the Style/MapJoin disable in error.rb: `details` comes from the API
    # and may hold nested arrays. `map(&:to_s).join` must inspect each element, NOT flatten it —
    # a bare `join` would recursively flatten and silently corrupt the message.
    it "inspects nested arrays in a top-level details array instead of flattening them" do
      error = described_class.new("Failed", response_body: { "message" => "Bad", "details" => [%w[a b], "c"] })
      expect(error.to_s).to include('["a", "b"], c')
    end

    it "formats a top-level details array when there is no message" do
      error = described_class.new("Failed", response_body: { "details" => %w[a b] })
      expect(error.to_s).to include("Details: a, b")
    end

    it "exposes status_code and response_body accessors" do
      error = described_class.new("Failed", status_code: 400, response_body: "raw")
      expect(error.status_code).to eq(400)
      expect(error.response_body).to eq("raw")
    end
  end

  describe "error class hierarchy" do
    it "defaults AuthenticationError to a 401 with a helpful message" do
      error = Openfactura::AuthenticationError.new
      expect(error).to be_a(Openfactura::ApiError)
      expect(error.status_code).to eq(401)
      expect(error.message).to match(/API key/)
    end

    it "defaults NotFoundError to a 404" do
      expect(Openfactura::NotFoundError.new.status_code).to eq(404)
    end

    it "defaults RateLimitError to a 429" do
      expect(Openfactura::RateLimitError.new.status_code).to eq(429)
    end

    it "defaults ServerError to a 500" do
      expect(Openfactura::ServerError.new.status_code).to eq(500)
    end

    it "carries a structured errors hash on ValidationError" do
      error = Openfactura::ValidationError.new("bad", errors: { receiver: [:rut] })
      expect(error).to be_a(Openfactura::Error)
      expect(error.errors).to eq({ receiver: [:rut] })
    end
  end
end
