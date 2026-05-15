require "rails_helper"

RSpec.describe MarketData::Queries::TrendingAssets do
  describe ".call" do
    it "returns only stock assets with non-nil price and change" do
      stock_up   = create(:asset, asset_type: :stock, current_price: 100, change_percent_24h: 5.0)
      stock_down = create(:asset, asset_type: :stock, current_price: 50,  change_percent_24h: -3.0)
      stock_nil_price  = create(:asset, asset_type: :stock, current_price: nil, change_percent_24h: 2.0)
      stock_nil_change = create(:asset, asset_type: :stock, current_price: 100, change_percent_24h: nil)
      crypto = create(:asset, :crypto, current_price: 1000, change_percent_24h: 10.0)

      result = described_class.call

      expect(result).to include(stock_up, stock_down)
      expect(result).not_to include(stock_nil_price, stock_nil_change, crypto)
    end

    it "orders by absolute change_percent_24h descending" do
      down_big   = create(:asset, asset_type: :stock, symbol: "DOWN_BIG", current_price: 50, change_percent_24h: -7.0)
      up_small   = create(:asset, asset_type: :stock, symbol: "UP_SMALL", current_price: 100, change_percent_24h: 2.0)
      up_huge    = create(:asset, asset_type: :stock, symbol: "UP_HUGE", current_price: 200, change_percent_24h: 12.0)

      expect(described_class.call.map(&:symbol)).to eq(%w[UP_HUGE DOWN_BIG UP_SMALL])
    end

    it "respects the limit parameter (default 5)" do
      8.times { |i| create(:asset, asset_type: :stock, symbol: "T#{i}", current_price: 100, change_percent_24h: i + 1) }

      expect(described_class.call.size).to eq(5)
      expect(described_class.call(limit: 3).size).to eq(3)
    end

    it "eager-loads trend_scores to prevent N+1 in the dashboard sidebar" do
      asset = create(:asset, asset_type: :stock, current_price: 100, change_percent_24h: 3.0)
      create(:trend_score, asset: asset)

      result_asset = described_class.call.first
      expect(result_asset.association(:trend_scores)).to be_loaded
    end
  end
end
