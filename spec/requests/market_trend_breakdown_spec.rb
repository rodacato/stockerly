require "rails_helper"

RSpec.describe "Market Listings Trend Breakdown", type: :request do
  let(:user) { create(:user) }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 150.0, country: "US") }

  before { login_as(user) }

  describe "GET /market" do
    it "renders trend score bar for listed assets" do
      create(:trend_score, asset: asset, score: 75, label: :moderate, direction: :upward)

      get market_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Moderate (75%)")
    end

    it "renders factor breakdown popover when factors data is present" do
      create(:trend_score, asset: asset, score: 80, label: :strong, direction: :upward,
        factors: { rsi: 72.5, momentum: 65.0, macd: 58.3, volume_trend: 61.0, ema_crossover: 70.2 })

      get market_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Factor Breakdown")
      expect(response.body).to include("RSI")
      expect(response.body).to include("MACD")
    end

    it "does not render factor breakdown for legacy scores without factors" do
      create(:trend_score, asset: asset, score: 60, label: :sideways, direction: :upward, factors: {})

      get market_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Factor Breakdown")
    end
  end
end
