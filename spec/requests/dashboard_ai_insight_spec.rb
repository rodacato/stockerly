require "rails_helper"

RSpec.describe "Dashboard AI Insight", type: :request do
  let!(:user) { create(:user, email: "ai@example.com", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0, change_percent_24h: 2.5) }

  before do
    create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
    create(:watchlist_item, user: user, asset: asset)
    login_as(user)
  end

  context "when AI insight exists" do
    let!(:insight) do
      create(:portfolio_insight, user: user,
        summary: "Portfolio is concentrated in tech sector.",
        observations: [ "Heavy AAPL exposure" ],
        risk_factors: [ "Single stock risk" ],
        generated_at: 1.hour.ago)
    end

    before { get dashboard_path }

    it "renders AI insight card" do
      expect(response.body).to include("AI Insight")
      expect(response.body).to include("Portfolio is concentrated in tech sector.")
    end

    it "shows AI-generated attribution label" do
      expect(response.body).to include("AI-generated")
    end

    it "shows disclaimer text" do
      expect(response.body).to include("AI-generated analysis, not financial advice")
    end
  end

  context "when no AI insight exists" do
    before { get dashboard_path }

    it "does not render AI insight card" do
      expect(response.body).not_to include("AI Insight")
    end
  end
end
