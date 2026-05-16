require "rails_helper"

RSpec.describe "Welcome", type: :request do
  let(:user) { create(:user, onboarded_at: nil) }

  describe "GET /welcome" do
    it "renders for a logged-in user who has not completed onboarding" do
      login_as_without_onboarding(user)
      get welcome_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hola")
      expect(response.body).to include("Te incorporaste a la beta cerrada")
      expect(response.body).to include("Esto es beta cerrada")
      expect(response.body).to include("Registra tu primer movimiento")
      expect(response.body).to include("Crea una watchlist")
      expect(response.body).to include("Configura una alerta")
    end

    it "redirects to dashboard for an already-onboarded user" do
      user.update!(onboarded_at: Time.current)
      login_as(user)
      get welcome_path

      expect(response).to redirect_to(dashboard_path)
    end

    it "blocks anonymous users" do
      get welcome_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /welcome" do
    it "marks the user as onboarded and redirects to dashboard" do
      login_as_without_onboarding(user)
      post complete_welcome_path

      expect(response).to redirect_to(dashboard_path)
      expect(user.reload).to be_onboarded
    end

    it "blocks anonymous users" do
      post complete_welcome_path
      expect(response).to redirect_to(login_path)
    end
  end
end
