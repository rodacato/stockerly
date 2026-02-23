require "rails_helper"

RSpec.describe Asset, type: :model do
  subject(:asset) { build(:asset) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires name" do
      asset.name = nil
      expect(asset).not_to be_valid
      expect(asset.errors[:name]).to include("can't be blank")
    end

    it "requires symbol" do
      asset.symbol = nil
      expect(asset).not_to be_valid
      expect(asset.errors[:symbol]).to include("can't be blank")
    end

    it "requires unique symbol (case-insensitive)" do
      create(:asset, symbol: "AAPL")
      asset.symbol = "aapl"
      expect(asset).not_to be_valid
      expect(asset.errors[:symbol]).to include("has already been taken")
    end
  end

  describe "enums" do
    it "defines asset_type enum" do
      expect(Asset.asset_types).to eq("stock" => 0, "crypto" => 1, "index" => 2, "etf" => 3)
    end

    it "defines sync_status enum" do
      expect(Asset.sync_statuses).to eq("active" => 0, "disabled" => 1, "sync_issue" => 2)
    end
  end

  describe "scopes" do
    let!(:stock)  { create(:asset, asset_type: :stock, sector: "Technology") }
    let!(:crypto) { create(:asset, :crypto) }

    it ".stocks returns only stocks" do
      expect(Asset.stocks).to contain_exactly(stock)
    end

    it ".cryptos returns only cryptos" do
      expect(Asset.cryptos).to contain_exactly(crypto)
    end

    it ".syncing returns active sync_status" do
      disabled = create(:asset, :disabled)
      expect(Asset.syncing).to include(stock)
      expect(Asset.syncing).not_to include(disabled)
    end

    it ".by_sector filters by sector" do
      expect(Asset.by_sector("Technology")).to contain_exactly(stock)
    end

    it ".by_sector returns all when sector is blank" do
      expect(Asset.by_sector(nil)).to include(stock, crypto)
    end

    it ".etfs returns only ETFs" do
      etf = create(:asset, :etf)
      expect(Asset.etfs).to contain_exactly(etf)
    end

    it ".by_country filters by country" do
      stock.update!(country: "US")
      crypto.update!(country: nil)
      expect(Asset.by_country("US")).to contain_exactly(stock)
    end

    it ".by_country returns all when country is blank" do
      expect(Asset.by_country(nil)).to include(stock, crypto)
    end
  end

  describe ".high_priority" do
    let!(:watched_asset) { create(:asset, symbol: "AAPL") }
    let!(:held_asset) { create(:asset, symbol: "MSFT") }
    let!(:alerted_asset) { create(:asset, symbol: "GOOGL") }
    let!(:ignored_asset) { create(:asset, symbol: "NFLX") }

    before do
      user = create(:user)
      create(:watchlist_item, user: user, asset: watched_asset)

      portfolio = create(:portfolio, user: user)
      create(:position, portfolio: portfolio, asset: held_asset, status: :open)

      create(:alert_rule, user: user, asset_symbol: "GOOGL", status: :active)
    end

    it "includes assets in watchlists" do
      expect(Asset.high_priority).to include(watched_asset)
    end

    it "includes assets with open positions" do
      expect(Asset.high_priority).to include(held_asset)
    end

    it "includes assets with active alert rules" do
      expect(Asset.high_priority).to include(alerted_asset)
    end

    it "excludes assets nobody is watching, holding, or alerting on" do
      expect(Asset.high_priority).not_to include(ignored_asset)
    end
  end

  describe ".low_priority" do
    let!(:watched_asset) { create(:asset, symbol: "AAPL") }
    let!(:ignored_asset) { create(:asset, symbol: "NFLX") }

    before do
      user = create(:user)
      create(:watchlist_item, user: user, asset: watched_asset)
    end

    it "includes only assets not in high_priority" do
      expect(Asset.low_priority).to include(ignored_asset)
      expect(Asset.low_priority).not_to include(watched_asset)
    end
  end

  describe "#latest_trend_score" do
    let(:asset) { create(:asset) }

    it "returns nil when no scores exist" do
      expect(asset.latest_trend_score).to be_nil
    end

    it "returns the most recent trend score" do
      old = create(:trend_score, asset: asset, calculated_at: 2.days.ago)
      recent = create(:trend_score, asset: asset, calculated_at: 1.hour.ago)
      expect(asset.latest_trend_score).to eq(recent)
    end
  end

  describe "#price_stale?" do
    it "returns true when price_updated_at is nil" do
      asset.price_updated_at = nil
      expect(asset.price_stale?).to be true
    end

    it "returns true when price is older than 15 minutes" do
      asset.price_updated_at = 20.minutes.ago
      expect(asset.price_stale?).to be true
    end

    it "returns false when price is recent" do
      asset.price_updated_at = 5.minutes.ago
      expect(asset.price_stale?).to be false
    end
  end
end
