require "rails_helper"

RSpec.describe "Empty state consistency", type: :request do
  let!(:user) { create(:user, email: "empty@example.com", password: "password123") }

  before { login_as(user) }

  # D43 dropped the open-positions list from Historial: it duplicated Holdings,
  # which is where that empty state lives now.
  describe "Holdings empty state uses component" do
    it "renders standardized empty state for an empty portfolio" do
      create(:portfolio, user: user)
      get assets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aún no tienes posiciones")
      expect(response.body).to include("account_balance_wallet")
    end
  end

  describe "alerts empty state uses component" do
    it "renders standardized empty state for alert rules" do
      get alerts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Todavía no tienes reglas")
      expect(response.body).to include("notifications")
    end
  end

  # The trade log moved into Historial with D60; its empty state moved with it
  # and is covered there, per section, in historial_spec.
  describe "Historial empty states use the component" do
    it "renders one per section rather than one for the page" do
      create(:portfolio, user: user)
      get positions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aún no registras movimientos")
      expect(response.body).to include("receipt_long")
    end
  end
end
