require "rails_helper"

RSpec.describe "TradingView Chart Widget", type: :request do
  let(:user) { create(:user) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders TradingView widget for stocks" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).to include('data-controller="tradingview"')
      expect(response.body).to include('data-tradingview-symbol-value="NASDAQ:AAPL"')
    end

    it "renders TradingView widget for crypto with USD suffix" do
      asset = create(:asset, symbol: "BTC", asset_type: :crypto, sync_status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).to include('data-tradingview-symbol-value="COINBASE:BTCUSD"')
    end

    it "renders TradingView widget for ETFs" do
      asset = create(:asset, symbol: "SPY", asset_type: :etf, sync_status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).to include('data-tradingview-symbol-value="AMEX:SPY"')
    end

    it "renders SVG price chart for fixed income assets" do
      asset = create(:asset, symbol: "CETES28", asset_type: :fixed_income, sync_status: :active)

      get market_asset_path(asset.symbol)

      expect(response.body).not_to include('data-controller="tradingview"')
    end
  end
end
