require "rails_helper"

RSpec.describe "Authenticated pages", type: :request do
  let!(:user) { create(:user, email: "dash@example.com", password: "password123") }

  before do
    login_as(user)
  end

  describe "GET /dashboard" do
    it "renders the dashboard with user name" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
      # Welcome flash carries the user's full name after login. The greeting
      # itself only renders when the user has a portfolio + watchlist (covered
      # by spec/requests/dashboard/dashboard_revamp_spec.rb).
      expect(response.body).to include(user.full_name)
    end
  end

  describe "GET /portfolio" do
    it "renders the Consolidado, with the lists at their own route" do
      portfolio = create(:portfolio, user: user)
      asset = create(:asset)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0)

      get portfolio_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("portfolios.show.titulo"))

      get positions_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Historial")
    end
  end

  describe "GET /alerts" do
    it "renders the alerts page with rules and live feed" do
      get alerts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tus reglas")
      expect(response.body).to include("Últimos disparos")
    end
  end

  describe "POST /alerts" do
    it "creates an alert and redirects back" do
      post alerts_path, params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0 } }
      expect(response).to redirect_to(alerts_path)
      follow_redirect!
      expect(response.body).to include("Regla creada")
    end
  end

  describe "PATCH /alerts/:id" do
    it "updates an alert and redirects back" do
      rule = create(:alert_rule, user: user)
      patch alert_path(rule), params: { alert: { asset_symbol: "TSLA", condition: "price_crosses_below", threshold_value: 150.0 } }
      expect(response).to redirect_to(alerts_path)
      follow_redirect!
      expect(response.body).to include("Regla actualizada")
    end
  end

  describe "DELETE /alerts/:id" do
    it "deletes an alert and redirects back" do
      rule = create(:alert_rule, user: user)
      delete alert_path(rule)
      expect(response).to redirect_to(alerts_path)
      follow_redirect!
      expect(response.body).to include("Regla eliminada")
    end
  end

  describe "GET /profile" do
    it "renders the profile with user info" do
      get profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.full_name)
      expect(response.body).to include("Información personal")
    end
  end

  describe "PATCH /profile" do
    it "updates profile and redirects back" do
      patch profile_path, params: { profile: { full_name: user.full_name, email: user.email } }
      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Perfil actualizado")
    end
  end

  describe "PATCH /profile/password" do
    it "changes password and redirects back" do
      patch change_password_path, params: {
        password_change: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
      }
      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Contraseña cambiada")
    end
  end
end
