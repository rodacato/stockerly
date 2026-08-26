require "rails_helper"

# Crypto-variant of /market/:symbol (S10 #93 — Stockerly-2.0). Adaptive
# tab list: only Resumen + Mercado, never Valoración / Dividendos /
# Estados financieros.
RSpec.describe "Market Crypto Asset Detail", type: :request do
  let!(:user) { create(:user, email: "crypto@example.com", password: "password123") }
  let!(:crypto_asset) { create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto, current_price: 67_250) }
  let!(:stock_asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227, country: "US") }
  let!(:crypto_fundamental) do
    create(:asset_fundamental, asset: crypto_asset, period_label: "CRYPTO_MARKET",
      metrics: {
        "market_cap" => "1310000000000",
        "circulating_supply" => "19600000",
        "total_supply" => "21000000",
        "fully_diluted_valuation" => "1080000000000",
        "total_volume_24h" => "28400000000",
        "ath_price" => "73750",
        "volume_market_cap_ratio" => "2.17"
      })
  end

  before { login_as(user) }

  describe "GET /market/:symbol for crypto" do
    it "renders the es-MX Cripto type chip" do
      get market_asset_path(crypto_asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/>\s*Cripto\s*</)
    end

    # D36 replaced the tab strip with one scroll: a crypto asset shows its
    # fundamentals section and never the equity-only ones.
    it "shows the fundamentals section and never the statement sections" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include(I18n.t("market.fundamentals_block.titulo"))
      expect(response.body).not_to include(I18n.t("market.statements_tab.titulo"))
      expect(response.body).not_to include(I18n.t("market.dividend_history.titulo"))
    end

    it "renders crypto-specific metrics" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include(I18n.t("market.metricas.circulating_supply.nombre"))
      expect(response.body).to include("FDV")
      expect(response.body).to include(I18n.t("market.metricas.total_volume_24h.nombre"))
      expect(response.body).to include(I18n.t("market.metricas.ath_price.nombre"))
      expect(response.body).to include(I18n.t("market.metricas.volume_market_cap_ratio.nombre"))
    end

    it "shows the CoinGecko source attribution (es-MX)" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include("CoinGecko")
      expect(response.body).not_to include("Alpha Vantage")
    end
  end

  describe "GET /market/:symbol for stocks (regression)" do
    it "renders the equity type chip and no crypto-only metrics" do
      get market_asset_path(stock_asset.symbol)

      expect(response.body).to match(/>\s*Acción\s*</)
      expect(response.body).not_to include(I18n.t("market.metricas.circulating_supply.nombre"))
    end
  end
end
