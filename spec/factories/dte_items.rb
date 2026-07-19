# frozen_string_literal: true

FactoryBot.define do
  # Builds a valid Openfactura::DSL::DteItem (a detail line). Use `build(:dte_item)`.
  factory :dte_item, class: "Openfactura::DSL::DteItem" do
    line_number { 1 }
    name { "Producto de prueba" }
    quantity { 1 }
    price { 2000 }
    amount { 2000 }

    initialize_with { new(attributes) }
  end
end
