require "rails_helper"

RSpec.describe Market::LoadAssetDetail do
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44) }

  describe ".call" do
    context "when asset exists with fundamentals" do
      let!(:overview) { create(:asset_fundamental, asset: asset, period_label: "OVERVIEW") }

      it "returns Success with asset, presenter and has_fundamentals true" do
        result = described_class.call(symbol: "AAPL")

        expect(result).to be_success
        data = result.value!
        expect(data[:asset]).to eq(asset)
        expect(data[:presenter]).to be_a(FundamentalPresenter)
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

    context "when asset does not exist" do
      it "returns Failure with :not_found" do
        result = described_class.call(symbol: "INVALID")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:not_found)
      end
    end
  end
end
