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

    it "renders only Resumen and Mercado tabs" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to match(/>\s*Resumen\s*</)
      expect(response.body).to match(/>\s*Mercado\s*</)
      expect(response.body).not_to match(/>\s*Valoración\s*</)
      expect(response.body).not_to match(/>\s*Dividendos\s*</)
      expect(response.body).not_to match(/>\s*Estados financieros\s*</)
    end

    it "renders crypto-specific metrics in the summary tab" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include("Circulating Supply")
      expect(response.body).to include("FDV")
      expect(response.body).to include("24h Volume")
      expect(response.body).to include("All-Time High")
      expect(response.body).to include("Vol / Market Cap")
    end

    it "shows the CoinGecko source attribution (es-MX)" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include("CoinGecko")
      expect(response.body).not_to include("Alpha Vantage")
    end
  end

  describe "GET /market/:symbol for stocks (regression)" do
    it "renders the trimmed equity tab set" do
      get market_asset_path(stock_asset.symbol)

      expect(response.body).to match(/>\s*Acción\s*</)
      expect(response.body).to match(/>\s*Resumen\s*</)
      # Mercado the navbar link is fine; only the Mercado *tab button* is
      # crypto-only. Assert that no `data-tabs-target="tab"` button carries
      # the Mercado label.
      expect(response.body).not_to match(/data-tabs-target="tab"[^>]*>\s*Mercado\s*</)
    end
  end
end
