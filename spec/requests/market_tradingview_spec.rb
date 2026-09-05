require "rails_helper"

# The opt-in TradingView chart (D66, #606). The load-bearing assertion is the
# negative one: D2's defect was a widget that reached a third party on every
# page load, and the whole design is that nothing does until the reader asks.
RSpec.describe "Market TradingView toggle", type: :request do
  let!(:user) { create(:user, email: "tv@example.com", password: "password123") }

  before { login_as(user) }

  def with_history(asset)
    3.times { |i| create(:asset_price_history, asset: asset, date: i.days.ago.to_date, close: 100 + i) }
    asset
  end

  describe "GET /market/:symbol" do
    it "offers the toggle on a stock" do
      asset = with_history(create(:asset, symbol: "NVDA"))

      get market_asset_path(asset.symbol)

      expect(response.body).to include("Gráfico de TradingView")
      expect(response.body).to include(market_asset_tradingview_path(asset.symbol))
    end

    it "offers it on an ETF too" do
      asset = with_history(create(:asset, :etf, symbol: "SPY"))

      get market_asset_path(asset.symbol)

      expect(response.body).to include("Gráfico de TradingView")
    end

    it "does not offer it on crypto, whose symbol needs an exchange we may not hold" do
      asset = with_history(create(:asset, :crypto, symbol: "BTC"))

      get market_asset_path(asset.symbol)

      expect(response.body).not_to include("Gráfico de TradingView")
    end

    it "does not offer it on fixed income, which TradingView has no symbol for" do
      asset = with_history(create(:asset, :fixed_income, symbol: "CETE28"))

      get market_asset_path(asset.symbol)

      expect(response.body).not_to include("Gráfico de TradingView")
    end

    it "refuses a symbol outside a ticker's alphabet, rather than escaping it into the script" do
      asset = with_history(create(:asset, symbol: "</script><script>alert(1)</script>"))

      get market_asset_path(asset.symbol)

      expect(response.body).not_to include("Gráfico de TradingView")
    end

    it "reaches no TradingView origin on page load — the frame ships empty" do
      asset = with_history(create(:asset, symbol: "AAPL"))

      get market_asset_path(asset.symbol)

      expect(response.body).to include('id="asset_tradingview"')
      expect(response.body).not_to include("s3.tradingview.com")
      expect(response.body).not_to include("tradingview-widget.com")
      expect(response.body).not_to include("tradingview-embed")
    end
  end

  describe "GET /market/:symbol/tradingview" do
    let(:asset) { with_history(create(:asset, symbol: "NVDA")) }

    it "renders the embed with the attribution the terms require" do
      get market_asset_tradingview_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="tradingview-embed"')
      expect(response.body).to include("tradingview-widget-copyright")
      expect(response.body).to include("by TradingView")
    end

    # The loader URL lives in the controller now, so the host it reaches is
    # pinned there rather than in a response body.
    it "loads the embed from the host the CSP names" do
      source = File.read("app/javascript/controllers/tradingview_embed_controller.js")

      expect(source).to include("https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js")
    end

    it "presets MACD and no moving average, whose period it cannot carry" do
      get market_asset_tradingview_path(asset.symbol)

      expect(response.body).to include("STD;MACD")
      expect(response.body).not_to include("STD;SMA")
    end

    it "records the open, which is the usage metric the card owes" do
      expect { get market_asset_tradingview_path(asset.symbol) }
        .to change { SystemLog.where(module_name: "tradingview").count }.by(1)

      expect(SystemLog.last.error_message).to eq("NVDA")
    end

    it "is not reachable for a symbol the toggle refuses" do
      odd = with_history(create(:asset, symbol: "BAD SYMBOL!"))

      get market_asset_tradingview_path(odd.symbol)

      expect(response).to have_http_status(:not_found)
    end

    it "is not reachable for an asset that renders no toggle" do
      crypto = with_history(create(:asset, :crypto, symbol: "BTC"))

      expect { get market_asset_tradingview_path(crypto.symbol) }
        .not_to(change { SystemLog.where(module_name: "tradingview").count })

      expect(response).to have_http_status(:not_found)
    end
  end
end
