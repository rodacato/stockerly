require "rails_helper"

# The opt-in TradingView chart (D66, #606). The load-bearing assertion is the
# negative one: D2's defect was a widget that reached a third party on every
# page load, and the whole design is that nothing does until the reader asks.
# Symbol shape is no longer asserted here — the catalogue cannot hold a
# non-ticker, and spec/models/asset_spec.rb owns that.
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

    # The embed took the whole card and there was no way back. One button does
    # both, because a second one would sit there dead until the first was used.
    it "carries both labels, so the button that opened it can also close it" do
      asset = with_history(create(:asset, symbol: "NVDA"))

      get market_asset_path(asset.symbol)

      expect(response.body).to include(I18n.t("market.tradingview_toggle.ocultar"))
      expect(response.body).to include('data-action="tradingview#toggle"')
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

    # `autosize` measured a container that lives in a frame the click had not
    # filled yet, so the widget drew itself far shorter than the box it was
    # given. An explicit number cannot be mismeasured.
    it "asks for a height rather than letting the widget measure an empty frame" do
      get market_asset_tradingview_path(asset.symbol)

      expect(response.body).to include("&quot;autosize&quot;:false")
      expect(response.body).to include("&quot;height&quot;:#{MarketHelper::TRADINGVIEW_HEIGHT}")
      expect(response.body).to include("height: #{MarketHelper::TRADINGVIEW_HEIGHT + MarketHelper::TRADINGVIEW_ATTRIBUTION}px")
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

    it "is not reachable for fixed income, which the toggle refuses" do
      cete = with_history(create(:asset, :fixed_income, symbol: "CETES_28D"))

      get market_asset_tradingview_path(cete.symbol)

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
