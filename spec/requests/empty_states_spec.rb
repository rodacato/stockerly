require "rails_helper"

RSpec.describe "Empty state consistency", type: :request do
  let!(:user) { create(:user, email: "empty@example.com", password: "password123") }

  before { login_as(user) }

  describe "portfolio empty states use component" do
    it "renders standardized empty state for open positions" do
      create(:portfolio, user: user)
      get portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aún no hay posiciones abiertas")
      expect(response.body).to include("trending_up")
    end
  end

  describe "alerts empty state uses component" do
    it "renders standardized empty state for alert rules" do
      get alerts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aún no tienes alertas configuradas")
      expect(response.body).to include("notifications_off")
    end
  end

  describe "trades empty state uses component" do
    it "renders standardized empty state for trade history" do
      get trades_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aún no hay movimientos")
      # Icon swapped to `history` in S11 #145 to match the Stockerly-2.0
      # mockup; previous `swap_horiz` no longer renders.
      expect(response.body).to include("history")
    end
  end
end
