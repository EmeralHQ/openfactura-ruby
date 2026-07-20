# frozen_string_literal: true

# Regression for #9 (OF-xx DocumentError mapping) and #10 (DocumentError hierarchy) at the RIGHT
# level: this drives `emit` through a REAL Client + WebMock, exercising the full
# request → handle_response → rescue → DocumentError path. The existing documents_spec.rb uses
# `instance_double(Client)` and hands in a pre-populated ApiError, which bypasses that path and
# hid these bugs (see #21).
RSpec.describe "Documents#emit error path (real HTTP)" do
  before do
    Openfactura.reset!
    Openfactura::Config.api_key = "test-api-key"
    Openfactura::Config.environment = :sandbox
    Openfactura::Config.api_base_url = nil
  end

  after { Openfactura.reset! }

  let(:dte) { build(:dte) }
  let(:issuer) { build(:issuer) }

  let(:of02_body) do
    {
      error: {
        code: "OF-02",
        message: "Faltan campos obligatorios en el dte",
        details: [{ field: "Encabezado.Receptor.RUTRecep", issue: "required" }]
      }
    }.to_json
  end

  def stub_emit(status:, body:)
    stub_request(:post, "#{Openfactura::Config.base_url}/v2/dte/document")
      .to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
  end

  it "raises a DocumentError carrying the OF-xx code and details on a 400 business error" do
    stub_emit(status: 400, body: of02_body)

    expect { Openfactura.documents.emit(dte: dte, issuer: issuer) }
      .to raise_error(Openfactura::DocumentError) do |error|
        expect(error.code).to eq("OF-02")
        expect(error.details_for_field("Encabezado.Receptor.RUTRecep")).not_to be_empty
      end
  end

  it "makes that DocumentError catchable as Openfactura::Error" do
    stub_emit(status: 400, body: of02_body)

    expect { Openfactura.documents.emit(dte: dte, issuer: issuer) }
      .to raise_error(Openfactura::Error)
  end

  it "raises a plain ApiError (not DocumentError) when the 400 body has no OF-xx error object" do
    stub_emit(status: 400, body: '{"detail":"malformed"}')

    expect { Openfactura.documents.emit(dte: dte, issuer: issuer) }
      .to raise_error(Openfactura::ApiError) { |e| expect(e).not_to be_a(Openfactura::DocumentError) }
  end
end
