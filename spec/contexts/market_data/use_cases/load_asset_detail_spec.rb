require "rails_helper"

RSpec.describe MarketData::LoadAssetDetail do
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44) }

  describe ".call" do
    context "when asset exists with fundamentals" do
      let!(:overview) { create(:asset_fundamental, asset: asset, period_label: "OVERVIEW") }

      it "returns Success with asset, presenter and has_fundamentals true" do
        result = described_class.call(symbol: "AAPL")

        expect(result).to be_success
        data = result.value!
        expect(data[:asset]).to eq(asset)
        expect(data[:presenter]).to be_a(MarketData::FundamentalPresenter)
        expect(data[:has_fundamentals]).to be(true)
      end

      it "prefers CALCULATED over OVERVIEW fundamentals" do
        calculated = create(:asset_fundamental, asset: asset, period_label: "CALCULATED",
          metrics: { "net_margin" => "0.25" }, source: "calculated")

        result = described_class.call(symbol: "AAPL")
        data = result.value!

        expect(data[:presenter].fundamental).to eq(calculated)
      end

      it "is case-insensitive for symbol lookup" do
        result = described_class.call(symbol: "aapl")

        expect(result).to be_success
        expect(result.value![:asset]).to eq(asset)
      end
    end

    context "when asset exists without fundamentals" do
      it "returns Success with has_fundamentals false" do
        result = described_class.call(symbol: "AAPL")

        expect(result).to be_success
        data = result.value!
        expect(data[:asset]).to eq(asset)
        expect(data[:has_fundamentals]).to be(false)
      end
    end

    context "when asset is a stock with price history" do
      let!(:fundamental) do
        create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
               metrics: { "eps" => "6.07" })
      end

      it "includes pe_history for stock assets" do
        create(:asset_price_history, asset: asset, date: 5.days.ago.to_date, close: 200.0)
        create(:asset_price_history, asset: asset, date: 3.days.ago.to_date, close: 210.0)

        result = described_class.call(symbol: "AAPL")
        data = result.value!

        expect(data[:pe_history]).to be_an(Array)
        expect(data[:pe_history].size).to eq(2)
        expect(data[:pe_history].first[:pe_ratio]).to be_present
      end
    end

    context "when asset is fixed income" do
      let!(:cetes) do
        create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 Days",
               yield_rate: 11.15, face_value: 10.0, maturity_date: 20.days.from_now.to_date)
      end

      it "returns asset with yield_data" do
        result = described_class.call(symbol: "CETES_28D")

        expect(result).to be_success
        data = result.value!
        expect(data[:asset]).to eq(cetes)
        expect(data[:yield_data]).to be_a(Hash)
        expect(data[:yield_data][:days_to_maturity]).to eq(20)
        expect(data[:yield_data][:discount_price]).to be_present
        expect(data[:yield_data][:total_return_100]).to be_present
      end

      it "sets has_fundamentals to false" do
        result = described_class.call(symbol: "CETES_28D")

        expect(result.value![:has_fundamentals]).to be(false)
      end
    end

    context "when asset does not exist" do
      it "returns Failure with :not_found" do
        result = described_class.call(symbol: "INVALID")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:not_found)
      end
    end
  end
end
