require "rails_helper"

RSpec.describe Administration::UseCases::Onboarding::SeedAssets do
  describe ".call" do
    it "creates assets from the catalog" do
      result = described_class.call(symbols: %w[AAPL BTC SPY])

      expect(result[:created]).to eq(3)
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

    it "keeps the catalogue's currency and logo, so a Mexican asset is not born in USD" do
      described_class.call(symbols: %w[IVVPESO.MX CETES_28D AAPL])

      expect(Asset.where(symbol: %w[IVVPESO.MX CETES_28D AAPL]).pluck(:symbol, :currency).to_h)
        .to eq("IVVPESO.MX" => "MXN", "CETES_28D" => "MXN", "AAPL" => "USD")
      expect(Asset.find_by(symbol: "AAPL").logo_url).to be_present
    end

    it "skips symbols not in catalog" do
      expect(described_class.call(symbols: %w[AAPL UNKNOWN_XYZ])[:created]).to eq(1)
      expect(Asset.count).to eq(1)
    end

    it "skips duplicates when assets already exist" do
      create(:asset, symbol: "AAPL")
      expect(described_class.call(symbols: %w[AAPL BTC])[:created]).to eq(2)
      expect(Asset.count).to eq(2)
    end

    it "returns zero when symbols is blank" do
      result = described_class.call(symbols: [])
      expect(result[:created]).to eq(0)
    end
  end
end
