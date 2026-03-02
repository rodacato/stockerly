require "rails_helper"

RSpec.describe "Phase 7 Domain Events" do
  describe AssetPriceUpdated do
    it "has required attributes" do
      event = described_class.new(asset_id: 1, symbol: "AAPL", old_price: "150.0", new_price: "155.0")

      expect(event.asset_id).to eq(1)
      expect(event.symbol).to eq("AAPL")
      expect(event.old_price).to eq("150.0")
      expect(event.new_price).to eq("155.0")
      expect(event.occurred_at).to be_present
    end
  end

  describe Alerts::AlertRuleCreated do
    it "has required attributes" do
      event = described_class.new(alert_rule_id: 1, user_id: 2, asset_symbol: "AAPL", condition: "price_crosses_above")

      expect(event.alert_rule_id).to eq(1)
      expect(event.condition).to eq("price_crosses_above")
    end
  end

  describe Alerts::AlertRuleTriggered do
    it "has required attributes" do
      event = described_class.new(alert_rule_id: 1, user_id: 2, asset_symbol: "AAPL", triggered_price: "200.0")

      expect(event.triggered_price).to eq("200.0")
    end
  end

  describe Trading::TradeExecuted do
    it "has required attributes" do
      event = described_class.new(trade_id: 1, user_id: 2, position_id: 3, side: "buy", shares: "10")

      expect(event.side).to eq("buy")
      expect(event.shares).to eq("10")
    end
  end

  describe Trading::PositionOpened do
    it "has required attributes" do
      event = described_class.new(position_id: 1, portfolio_id: 2, asset_symbol: "AAPL")

      expect(event.asset_symbol).to eq("AAPL")
    end
  end

  describe Trading::PositionClosed do
    it "has required attributes" do
      event = described_class.new(position_id: 1, portfolio_id: 2, asset_symbol: "AAPL")

      expect(event.asset_symbol).to eq("AAPL")
    end
  end

  describe WatchlistItemAdded do
    it "has required attributes" do
      event = described_class.new(watchlist_item_id: 1, user_id: 2, asset_symbol: "AAPL")

      expect(event.watchlist_item_id).to eq(1)
    end
  end

  describe Trading::PortfolioSnapshotTaken do
    it "has required attributes" do
      event = described_class.new(snapshot_id: 1, portfolio_id: 2, total_value: "10000.0")

      expect(event.total_value).to eq("10000.0")
    end
  end

  describe NotificationCreated do
    it "has required attributes" do
      event = described_class.new(notification_id: 1, user_id: 2, title: "Test")

      expect(event.title).to eq("Test")
    end
  end

  describe FxRatesRefreshed do
    it "can be instantiated with no attributes" do
      event = described_class.new

      expect(event.occurred_at).to be_present
    end
  end

  describe CsvExported do
    it "has required attributes" do
      event = described_class.new(user_id: 1, export_type: "trades")

      expect(event.export_type).to eq("trades")
    end
  end

  describe IntegrationConnected do
    it "has required attributes" do
      event = described_class.new(integration_id: 1, provider_name: "Polygon.io")

      expect(event.provider_name).to eq("Polygon.io")
    end
  end
end
