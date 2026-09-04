require "rails_helper"

RSpec.describe Administration::UseCases::Assets::SeedCatalog do
  let(:catalog) { Administration::Domain::AssetCatalog }

  it "creates every asset the catalogue declares" do
    expect { described_class.call }.to change(Asset, :count).by(catalog.seedable.size)

    expect(Asset.pluck(:symbol)).to match_array(catalog.seedable.pluck(:symbol))
  end

  it "is idempotent — a second run creates nothing" do
    described_class.call

    expect { described_class.call }.not_to change(Asset, :count)
  end

  it "gives crypto its CoinGecko logo and leaves fixed income without one" do
    described_class.call

    expect(Asset.find_by(symbol: "BTC").logo_url).to include("coingecko")
    expect(Asset.find_by(symbol: "CETES_28D").logo_url).to be_nil
  end

  describe "correcting rows that predate a catalogue change" do
    it "fixes a currency the catalogue now declares" do
      create(:asset, symbol: "CETES_28D", currency: "USD", asset_type: :fixed_income)

      expect { described_class.call }.to change { Asset.find_by(symbol: "CETES_28D").currency }.from("USD").to("MXN")
    end

    # Currency decides what money on the asset means; rewriting it under an
    # existing trade would silently restate that trade's cost.
    it "refuses to change the currency of an asset that has been traded, and says which" do
      asset = create(:asset, symbol: "CETES_28D", currency: "USD", asset_type: :fixed_income)
      create(:trade, asset: asset, portfolio: create(:portfolio))

      result = described_class.call

      expect(asset.reload.currency).to eq("USD")
      expect(result[:skipped]).to eq([ "CETES_28D" ])
    end

    it "backfills a blank logo without overwriting one already set" do
      create(:asset, symbol: "AAPL", logo_url: nil)
      create(:asset, symbol: "MSFT", logo_url: "https://example.com/custom.png")

      described_class.call

      expect(Asset.find_by(symbol: "AAPL").logo_url).to include("parqet")
      expect(Asset.find_by(symbol: "MSFT").logo_url).to eq("https://example.com/custom.png")
    end
  end
end
