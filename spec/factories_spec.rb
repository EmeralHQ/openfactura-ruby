# frozen_string_literal: true

# Exercises every factory so a broken definition fails here, and documents how they compose.
RSpec.describe "FactoryBot factories" do
  it "builds a valid receiver" do
    receiver = build(:receiver)
    expect(receiver).to be_a(Openfactura::DSL::Receiver)
    expect { receiver.to_api_hash }.not_to raise_error
  end

  it "builds a valid issuer" do
    issuer = build(:issuer)
    expect(issuer).to be_a(Openfactura::DSL::Issuer)
    expect { issuer.to_api_hash }.not_to raise_error
  end

  it "builds a valid dte_item" do
    item = build(:dte_item)
    expect(item).to be_a(Openfactura::DSL::DteItem)
    expect { item.to_api_hash }.not_to raise_error
  end

  it "builds valid totals" do
    totals = build(:totals)
    expect(totals).to be_a(Openfactura::DSL::Totals)
    expect { totals.to_api_hash }.not_to raise_error
  end

  it "builds a dte that assembles into the API envelope" do
    dte = build(:dte)
    expect(dte).to be_a(Openfactura::DSL::Dte)

    hash = dte.to_api_hash
    expect(hash).to include(:Encabezado, :Detalle)
    expect(hash[:Encabezado][:IdDoc][:TipoDTE]).to eq(33)
    expect(hash[:Detalle]).to be_an(Array)
    expect(hash[:Detalle]).not_to be_empty
  end

  it "allows overriding any attribute" do
    expect(build(:dte, type: 61).type).to eq(61)
    expect(build(:receiver, rut: "1-9").rut).to eq("1-9")
  end
end
