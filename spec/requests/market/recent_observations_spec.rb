require "rails_helper"

RSpec.describe "Market detail — Recent Observations block (#40 JTBD #6)", type: :request do
  let(:user) { create(:user, email: "viewer@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock, current_price: 145.0) }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders recent observations when they exist" do
      create(:technical_observation, asset: asset, observation_type: "rsi_oversold_entered", observed_at: 1.day.ago)
      create(:technical_observation, asset: asset, observation_type: "ma200_crossed_below", observed_at: 5.days.ago)

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recent Observations")
      expect(response.body).to include("entered oversold zone")
      expect(response.body).to include("crossed below its MA200")
    end

    it "does not render the block when the asset has no observations" do
      get market_asset_path(asset.symbol)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Recent Observations")
    end

    it "filters to observations within the last 30 days" do
      create(:technical_observation, asset: asset, observation_type: "rsi_oversold_entered", observed_at: 5.days.ago)
      create(:technical_observation, asset: asset, observation_type: "ma50_crossed_above", observed_at: 45.days.ago)

      get market_asset_path(asset.symbol)
      expect(response.body).to include("entered oversold zone")
      expect(response.body).not_to include("crossed above its MA50")
    end

    it "uses descriptive copy only (ADR-001)" do
      create(:technical_observation, asset: asset, observation_type: "bb_upper_breached", observed_at: 1.hour.ago)

      get market_asset_path(asset.symbol)
      body = response.body
      expect(body).to include("broke its upper Bollinger Band")
      expect(body).not_to match(/\b(buy|sell|rebalance|consider)\b/i)
      expect(body).not_to match(/you should|time to/i)
    end
  end
end
