# frozen_string_literal: true

FactoryBot.define do
  # Builds a valid Openfactura::DSL::Issuer. Use `build(:issuer)`.
  factory :issuer, class: "Openfactura::DSL::Issuer" do
    rut { "76795561-8" }
    business_name { "HAULMER SPA" }
    business_activity { "VENTA AL POR MENOR POR CORREO" }
    economic_activity_code { "479100" }
    address { "ARTURO PRAT 527" }
    commune { "Curicó" }

    initialize_with { new(attributes) }
  end
end
