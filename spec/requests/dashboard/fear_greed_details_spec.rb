require "rails_helper"

RSpec.describe "Dashboard F&G sub-indicators", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
    create(:watchlist_item, user: user)
  end

  describe "GET /dashboard" do
    context "with component_data present" do
      before do
        create(:fear_greed_reading,
          index_type: "stocks",
          value: 65,
          classification: "Greed",
          source: "cnn",
          fetched_at: 1.hour.ago,
          component_data: {
            "market_momentum_sp500" => { "score" => 72.5, "rating" => "Greed" },
            "stock_price_strength" => { "score" => 58.0, "rating" => "Greed" },
            "put_call_options" => { "score" => 45.0, "rating" => "Neutral" }
          })
      end

      it "displays sub-indicators toggle button" do
        get dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sub-Indicators")
      end

      it "includes indicator labels" do
        get dashboard_path

        expect(response.body).to include("Market Momentum")
        expect(response.body).to include("Price Strength")
        expect(response.body).to include("Put/Call Options")
      end
    end

    context "without component_data" do
      before do
        create(:fear_greed_reading,
          index_type: "crypto",
          value: 40,
          classification: "Fear",
          source: "alternative.me",
          fetched_at: 1.hour.ago,
          component_data: {})
      end

      it "does not show sub-indicators section" do
        get dashboard_path

        expect(response.body).not_to include("Sub-Indicators")
      end
    end
  end
end
