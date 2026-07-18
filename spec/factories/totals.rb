# frozen_string_literal: true

FactoryBot.define do
  # Builds a valid Openfactura::DSL::Totals. Use `build(:totals)`.
  factory :totals, class: "Openfactura::DSL::Totals" do
    total_amount { 2380 }
    net_amount { 2000 }
    tax_amount { 380 }

    initialize_with { new(attributes) }
  end
end
