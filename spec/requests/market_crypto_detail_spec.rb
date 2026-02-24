require "rails_helper"

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
    it "renders Digital Asset type badge" do
      get market_asset_path(crypto_asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Digital Asset")
    end

    it "renders only Summary and Market Data tabs" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include("Summary")
      expect(response.body).to include("Market Data")
      expect(response.body).not_to include("Profitability")
      expect(response.body).not_to include("Dividends")
      expect(response.body).not_to include("Statements")
    end

    it "renders crypto-specific metrics in summary tab" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include("Circulating Supply")
      expect(response.body).to include("FDV")
      expect(response.body).to include("24h Volume")
      expect(response.body).to include("All-Time High")
      expect(response.body).to include("Vol / Market Cap")
    end

    it "shows CoinGecko source attribution" do
      get market_asset_path(crypto_asset.symbol)

      expect(response.body).to include("CoinGecko")
      expect(response.body).not_to include("Alpha Vantage")
    end
  end

  describe "GET /market/:symbol for stocks (regression)" do
    it "still renders all 7 stock tabs" do
      get market_asset_path(stock_asset.symbol)

      expect(response.body).to include("Equity")
      expect(response.body).to include("Summary")
      expect(response.body).to include("Valuation")
      expect(response.body).to include("Profitability")
      expect(response.body).to include("Health")
      expect(response.body).to include("Growth")
      expect(response.body).to include("Dividends")
      expect(response.body).to include("Statements")
      expect(response.body).not_to include("Digital Asset")
    end
  end
end
