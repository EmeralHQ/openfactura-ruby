# frozen_string_literal: true

RSpec.describe Openfactura::DSL::Dte do
  let(:receiver) do
    Openfactura::DSL::Receiver.new(
      rut: "76430498-5",
      business_name: "HOSTY SPA",
      business_activity: "ACTIVIDADES DE CONSULTORIA",
      contact: "Juan Pérez",
      address: "ARTURO PRAT 527",
      commune: "Curicó"
    )
  end

  let(:item) do
    Openfactura::DSL::DteItem.new(
      line_number: 1,
      name: "Producto",
      quantity: 1,
      price: 2000,
      amount: 2000
    )
  end

  let(:totals) do
    Openfactura::DSL::Totals.new(
      total_amount: 2380,
      tax_rate: "19"
    )
  end

  describe "#initialize" do
    context "with valid DTE type" do
      it "creates a DTE with valid type" do
        dte = described_class.new(
          type: 33,
          receiver: receiver,
          items: [item],
          totals: totals
        )

        expect(dte.type).to eq(33)
        expect(dte.receiver).to be_a(Openfactura::DSL::Receiver)
        expect(dte.items).to be_an(Array)
        expect(dte.items.first).to be_a(Openfactura::DSL::DteItem)
        expect(dte.totals).to be_a(Openfactura::DSL::Totals)
      end

      it "defaults folio to 0" do
        dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)
        expect(dte.folio).to eq(0)
      end

      it "defaults emission_date to today" do
        dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)
        expect(dte.emission_date).to eq(Date.today.strftime("%Y-%m-%d"))
      end

      it "accepts custom emission_date" do
        dte = described_class.new(
          type: 33,
          receiver: receiver,
          items: [item],
          totals: totals,
          emission_date: "2024-01-15"
        )
        expect(dte.emission_date).to eq("2024-01-15")
      end

      it "converts receiver hash to Receiver object" do
        receiver_hash = {
          rut: "76430498-5",
          business_name: "HOSTY SPA",
          business_activity: "ACTIVIDADES DE CONSULTORIA",
          contact: "Juan Pérez",
          address: "ARTURO PRAT 527",
          commune: "Curicó"
        }

        dte = described_class.new(
          type: 33,
          receiver: receiver_hash,
          items: [item],
          totals: totals
        )

        expect(dte.receiver).to be_a(Openfactura::DSL::Receiver)
        expect(dte.receiver.rut).to eq("76430498-5")
      end

      it "converts items array of hashes to DteItem objects" do
        items_array = [
          { line_number: 1, name: "Producto 1", quantity: 1, price: 1000, amount: 1000 },
          { line_number: 2, name: "Producto 2", quantity: 2, price: 500, amount: 1000 }
        ]

        dte = described_class.new(
          type: 33,
          receiver: receiver,
          items: items_array,
          totals: totals
        )

        expect(dte.items.length).to eq(2)
        expect(dte.items.first).to be_a(Openfactura::DSL::DteItem)
        expect(dte.items.first.name).to eq("Producto 1")
      end

      it "converts totals hash to Totals object" do
        totals_hash = {
          total_amount: 2380,
          tax_rate: "19"
        }

        dte = described_class.new(
          type: 33,
          receiver: receiver,
          items: [item],
          totals: totals_hash
        )

        expect(dte.totals).to be_a(Openfactura::DSL::Totals)
        expect(dte.totals.total_amount).to eq(2380)
      end

      it "accepts issuer object" do
        issuer = Openfactura::DSL::Issuer.new(
          rut: "76795561-8",
          business_name: "HAULMER SPA",
          business_activity: "VENTA AL POR MENOR",
          economic_activity_code: "479100",
          address: "ARTURO PRAT 527",
          commune: "Curicó",
          sii_branch_code: "81303347"
        )

        dte = described_class.new(
          type: 33,
          receiver: receiver,
          items: [item],
          totals: totals,
          issuer: issuer
        )

        expect(dte.issuer).to eq(issuer)
      end
    end

    context "with invalid DTE type" do
      it "raises ArgumentError for invalid type" do
        expect do
          described_class.new(type: 99, receiver: receiver, items: [item], totals: totals)
        end.to raise_error(ArgumentError, /Invalid DTE type/)
      end

      it "raises ArgumentError when type is nil" do
        expect do
          described_class.new(type: nil, receiver: receiver, items: [item], totals: totals)
        end.to raise_error(ArgumentError, "type is required")
      end
    end

    context "with invalid emission_date" do
      it "raises ArgumentError for date before minimum" do
        expect do
          described_class.new(
            type: 33,
            receiver: receiver,
            items: [item],
            totals: totals,
            emission_date: "2003-03-31"
          )
        end.to raise_error(ArgumentError, /Date must be >= 2003-04-01/)
      end

      it "raises ArgumentError for date after maximum" do
        expect do
          described_class.new(
            type: 33,
            receiver: receiver,
            items: [item],
            totals: totals,
            emission_date: "2051-01-01"
          )
        end.to raise_error(ArgumentError, /Date must be <= 2050-12-31/)
      end

      it "raises ArgumentError for invalid date format" do
        expect do
          described_class.new(
            type: 33,
            receiver: receiver,
            items: [item],
            totals: totals,
            emission_date: "2024/01/15"
          )
        end.to raise_error(ArgumentError, /Expected format: YYYY-MM-DD/)
      end

      it "raises ArgumentError for invalid date" do
        expect do
          described_class.new(
            type: 33,
            receiver: receiver,
            items: [item],
            totals: totals,
            emission_date: "2024-02-30"
          )
        end.to raise_error(ArgumentError, /Invalid emission_date/)
      end
    end
  end

  describe "#to_api_hash" do
    it "converts DTE to API format hash" do
      dte = described_class.new(
        type: 33,
        folio: 123,
        emission_date: "2024-01-15",
        receiver: receiver,
        items: [item],
        totals: totals
      )

      api_hash = dte.to_api_hash

      expect(api_hash).to have_key(:Encabezado)
      expect(api_hash[:Encabezado]).to have_key(:IdDoc)
      expect(api_hash[:Encabezado][:IdDoc][:TipoDTE]).to eq(33)
      expect(api_hash[:Encabezado][:IdDoc][:Folio]).to eq(123)
      expect(api_hash[:Encabezado][:IdDoc][:FchEmis]).to eq("2024-01-15")
      expect(api_hash[:Encabezado]).to have_key(:Receptor)
      expect(api_hash[:Encabezado]).to have_key(:Totales)
      expect(api_hash).to have_key(:Detalle)
      expect(api_hash[:Detalle]).to be_an(Array)
    end

    it "includes issuer in API hash when present" do
      issuer = Openfactura::DSL::Issuer.new(
        rut: "76795561-8",
        business_name: "HAULMER SPA",
        business_activity: "VENTA AL POR MENOR",
        economic_activity_code: "479100",
        address: "ARTURO PRAT 527",
        commune: "Curicó",
        sii_branch_code: "81303347"
      )

      dte = described_class.new(
        type: 33,
        receiver: receiver,
        items: [item],
        totals: totals,
        issuer: issuer
      )

      api_hash = dte.to_api_hash

      expect(api_hash[:Encabezado]).to have_key(:Emisor)
      expect(api_hash[:Encabezado][:Emisor][:RUTEmisor]).to eq("76795561-8")
      expect(api_hash[:Encabezado][:Emisor][:RznSoc]).to eq("HAULMER SPA")
    end

    it "includes optional transaction types" do
      dte = described_class.new(
        type: 33,
        receiver: receiver,
        items: [item],
        totals: totals,
        purchase_transaction_type: "1",
        sale_transaction_type: "2",
        payment_form: "3"
      )

      api_hash = dte.to_api_hash

      expect(api_hash[:Encabezado][:IdDoc][:TpoTranCompra]).to eq("1")
      expect(api_hash[:Encabezado][:IdDoc][:TpoTranVenta]).to eq("2")
      expect(api_hash[:Encabezado][:IdDoc][:FmaPago]).to eq("3")
    end
  end

  describe "#type=" do
    it "validates type when setting" do
      dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)

      expect { dte.type = 61 }.not_to raise_error
      expect(dte.type).to eq(61)
    end

    it "raises ArgumentError for invalid type" do
      dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)

      expect { dte.type = 99 }.to raise_error(ArgumentError, /Invalid DTE type/)
    end
  end

  describe "#emission_date=" do
    it "validates emission_date when setting" do
      dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)

      expect { dte.emission_date = "2024-06-15" }.not_to raise_error
      expect(dte.emission_date).to eq("2024-06-15")
    end

    it "raises ArgumentError for invalid date format" do
      dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)

      expect { dte.emission_date = "2024/06/15" }.to raise_error(ArgumentError, /Expected format: YYYY-MM-DD/)
    end

    it "raises ArgumentError for date out of range" do
      dte = described_class.new(type: 33, receiver: receiver, items: [item], totals: totals)

      expect { dte.emission_date = "2000-01-01" }.to raise_error(ArgumentError, /Date must be >= 2003-04-01/)
    end
  end
end
