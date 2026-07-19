# frozen_string_literal: true

FactoryBot.define do
  # Builds a valid Openfactura::DSL::Receiver. Use `build(:receiver)`.
  factory :receiver, class: "Openfactura::DSL::Receiver" do
    rut { "76430498-5" }
    business_name { "HOSTY SPA" }
    business_activity { "ACTIVIDADES DE CONSULTORIA" }
    contact { "Juan Pérez" }
    address { "ARTURO PRAT 527" }
    commune { "Curicó" }

    initialize_with { new(attributes) }
  end
end
