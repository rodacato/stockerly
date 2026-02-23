require "rails_helper"

RSpec.describe Trends::LoadAssetTrend do
  let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock) }
  let!(:score) { create(:trend_score, asset: asset, score: 85) }

  describe "#call" do
    it "loads asset by symbol" do
      result = described_class.call(symbol: "AAPL")
      expect(result).to be_success
      expect(result.value![:asset]).to eq(asset)
    end

    it "loads the latest trend score" do
      result = described_class.call(symbol: "AAPL")
      expect(result.value![:score]).to eq(score)
    end

    it "loads price history" do
      create(:asset_price_history, asset: asset, date: 1.day.ago, close: 185.50)
      result = described_class.call(symbol: "AAPL")
      expect(result.value![:history]).not_to be_empty
    end

    it "returns first stock if no symbol given" do
      result = described_class.call
      expect(result).to be_success
      expect(result.value![:asset]).to eq(asset)
    end

    it "returns failure if asset not found" do
      result = described_class.call(symbol: "ZZZZ")
      expect(result).to be_failure
      expect(result.failure).to eq([ :not_found, "Asset not found" ])
    end

    it "is case insensitive for symbol lookup" do
      result = described_class.call(symbol: "aapl")
      expect(result).to be_success
      expect(result.value![:asset]).to eq(asset)
    end
  end
end
