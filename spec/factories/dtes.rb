# frozen_string_literal: true

FactoryBot.define do
  # Builds a valid Openfactura::DSL::Dte (type 33) with a receiver, one item and totals.
  # Use `build(:dte)`, or override any part: `build(:dte, type: 61)`, `build(:dte, items: [...])`.
  factory :dte, class: "Openfactura::DSL::Dte" do
    type { 33 }
    receiver { build(:receiver) }
    items { [build(:dte_item)] }
    totals { build(:totals) }

    initialize_with { new(attributes) }
  end
end
