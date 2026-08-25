require "rails_helper"

RSpec.describe "Help", type: :request do
  let(:user) { create(:user) }

  describe "GET /help" do
    it "renders for a logged-in user" do
      login_as(user)
      get help_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ayuda y soporte")
      expect(response.body).to include("Software en desarrollo")
      expect(response.body).to include("Repórtalo aquí")
    end

    it "sends a user who has not finished onboarding back into the wizard" do
      onboarding_pending = create(:user, onboarded_at: nil)
      login_as_without_onboarding(onboarding_pending)

      get help_path

      expect(response).to redirect_to(onboarding_integrations_path)
    end

    it "blocks anonymous users" do
      get help_path
      expect(response).to redirect_to(login_path)
    end
  end
end
