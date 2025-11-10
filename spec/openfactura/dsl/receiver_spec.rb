# frozen_string_literal: true

RSpec.describe Openfactura::DSL::Receiver do
  describe "#initialize" do
    it "initializes with standard attributes" do
      receiver = described_class.new(
        rut: "76430498-5",
        business_name: "HOSTY SPA",
        business_activity: "ACTIVIDADES DE CONSULTORIA",
        contact: "Juan Pérez",
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      expect(receiver.rut).to eq("76430498-5")
      expect(receiver.business_name).to eq("HOSTY SPA")
      expect(receiver.business_activity).to eq("ACTIVIDADES DE CONSULTORIA")
      expect(receiver.contact).to eq("Juan Pérez")
      expect(receiver.address).to eq("ARTURO PRAT 527")
      expect(receiver.commune).to eq("Curicó")
    end

    it "accepts string keys" do
      receiver = described_class.new(
        "rut" => "76430498-5",
        "business_name" => "HOSTY SPA",
        "address" => "ARTURO PRAT 527"
      )

      expect(receiver.rut).to eq("76430498-5")
      expect(receiver.business_name).to eq("HOSTY SPA")
    end
  end

  describe "#to_api_hash" do
    it "converts to API format hash" do
      receiver = described_class.new(
        rut: "76430498-5",
        business_name: "HOSTY SPA",
        business_activity: "ACTIVIDADES DE CONSULTORIA",
        contact: "Juan Pérez",
        address: "ARTURO PRAT 527",
        commune: "Curicó"
      )

      api_hash = receiver.to_api_hash

      expect(api_hash).to eq({
        RUTRecep: "76430498-5",
        RznSocRecep: "HOSTY SPA",
        GiroRecep: "ACTIVIDADES DE CONSULTORIA",
        Contacto: "Juan Pérez",
        DirRecep: "ARTURO PRAT 527",
        CmnaRecep: "Curicó"
      })
    end

    it "excludes nil values" do
      receiver = described_class.new(
        rut: "76430498-5",
        business_name: "HOSTY SPA"
      )

      api_hash = receiver.to_api_hash

      expect(api_hash).not_to have_key(:GiroRecep)
      expect(api_hash).not_to have_key(:Contacto)
    end
  end
end
