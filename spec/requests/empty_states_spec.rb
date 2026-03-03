require "rails_helper"

RSpec.describe "Empty state consistency", type: :request do
  let!(:user) { create(:user, email: "empty@example.com", password: "password123") }

  before { login_as(user) }

  describe "portfolio empty states use component" do
    it "renders standardized empty state for open positions" do
      create(:portfolio, user: user)
      get portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No open positions yet")
      expect(response.body).to include("trending_up")
    end
  end

  describe "alerts empty state uses component" do
    it "renders standardized empty state for alert rules" do
      get alerts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No alert rules configured")
      expect(response.body).to include("notifications_none")
    end
  end

  describe "trades empty state uses component" do
    it "renders standardized empty state for trade history" do
      get trades_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No trades yet")
      expect(response.body).to include("swap_horiz")
    end
  end
end
