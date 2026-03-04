require "rails_helper"

RSpec.describe Administration::UseCases::Onboarding::SeedAssets do
  describe ".call" do
    it "creates assets from the catalog" do
      result = described_class.call(symbols: %w[AAPL BTC SPY])

      expect(result).to be_success
      expect(result.value![:created]).to eq(3)
      expect(Asset.pluck(:symbol)).to include("AAPL", "BTC", "SPY")
    end

    it "sets correct attributes from catalog" do
      described_class.call(symbols: %w[AAPL])

      asset = Asset.find_by(symbol: "AAPL")
      expect(asset.name).to eq("Apple Inc.")
      expect(asset.asset_type).to eq("stock")
      expect(asset.exchange).to eq("NASDAQ")
      expect(asset.sector).to eq("Technology")
    end

    it "skips symbols not in catalog" do
      result = described_class.call(symbols: %w[AAPL UNKNOWN_XYZ])

      expect(result).to be_success
      expect(Asset.count).to eq(1)
    end

    it "skips duplicates when assets already exist" do
      create(:asset, symbol: "AAPL")
      result = described_class.call(symbols: %w[AAPL BTC])

      expect(result).to be_success
      expect(Asset.count).to eq(2)
    end

    it "returns zero when symbols is blank" do
      result = described_class.call(symbols: [])
      expect(result).to be_success
      expect(result.value![:created]).to eq(0)
    end
  end
end
