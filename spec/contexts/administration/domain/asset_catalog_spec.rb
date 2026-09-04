require "rails_helper"

RSpec.describe Administration::Domain::AssetCatalog do
  describe ".all" do
    it "returns a hash of categories" do
      catalog = described_class.all
      expect(catalog).to be_a(Hash)
      expect(catalog.keys).to include(:us_stocks, :crypto, :etfs, :mexican_stocks, :fixed_income)
    end
  end

  describe ".flat" do
    it "returns all assets as a flat array" do
      flat = described_class.flat
      expect(flat).to be_an(Array)
      expect(flat.size).to be >= 25
      expect(flat.first).to include(:symbol, :name, :asset_type)
    end
  end

  describe ".symbols" do
    it "returns all symbols" do
      symbols = described_class.symbols
      expect(symbols).to include("AAPL", "BTC", "SPY", "CETES_28D")
    end
  end

  describe ".find_by_symbols" do
    it "returns matching entries" do
      results = described_class.find_by_symbols(%w[AAPL BTC])
      expect(results.size).to eq(2)
      expect(results.pluck(:symbol)).to contain_exactly("AAPL", "BTC")
    end

    it "ignores unknown symbols" do
      results = described_class.find_by_symbols(%w[AAPL UNKNOWN])
      expect(results.size).to eq(1)
    end
  end

  describe ".category_label" do
    it "returns the es-MX label for a known key" do
      expect(described_class.category_label(:us_stocks)).to eq("Acciones · EE. UU.")
      expect(described_class.category_label(:crypto)).to eq("Cripto")
    end

    it "falls back to the humanized key rather than an I18n error string" do
      expect(described_class.category_label(:some_new_bucket)).to eq("Some new bucket")
    end
  end

  describe "DEFAULT_SELECTED" do
    it "contains popular symbols" do
      expect(described_class::DEFAULT_SELECTED).to include("AAPL", "BTC", "SPY")
    end
  end

  describe "the one list" do
    it "seeds the picker plus the system rows, and offers only the picker" do
      expect(described_class.seedable.size).to eq(described_class.flat.size + described_class::SYSTEM.size)
      expect(described_class.symbols).not_to include("VIX")
      expect(described_class.seedable.pluck(:symbol)).to include("VIX")
    end

    # Every MX row used to omit currency, so each was created with the column
    # default — CETES and a peso-quoted ETF stored as USD.
    it "declares MXN on every peso-denominated row" do
      mx = described_class.seedable.select { |a| a[:country] == "MX" }

      expect(mx).not_to be_empty
      expect(mx.pluck(:currency).uniq).to eq([ "MXN" ])
    end

    it "gives every row the fields an Asset needs to be valid" do
      described_class.seedable.each do |attrs|
        asset = Asset.new(attrs.merge(sync_status: :active))
        expect(asset).to be_valid, "#{attrs[:symbol]}: #{asset.errors.full_messages.join(', ')}"
      end
    end
  end

  describe ".logo_url_for" do
    it "sends crypto to CoinGecko and everything else to Parqet" do
      expect(described_class.logo_url_for(symbol: "BTC", asset_type: "crypto")).to include("coingecko")
      expect(described_class.logo_url_for(symbol: "AAPL", asset_type: "stock", country: "US")).to include("parqet")
    end

    it "has no logo for the kinds nobody publishes one for" do
      expect(described_class.logo_url_for(symbol: "CETES_28D", asset_type: "fixed_income", country: "MX")).to be_nil
      expect(described_class.logo_url_for(symbol: "VIX", asset_type: "index", country: "US")).to be_nil
      expect(described_class.logo_url_for(symbol: "IVVPESO.MX", asset_type: "etf", country: "MX")).to be_nil
    end
  end
end
