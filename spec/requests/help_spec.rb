require "rails_helper"

RSpec.describe "Help", type: :request do
  let(:user) { create(:user) }

  describe "GET /help" do
    it "renders for a logged-in user" do
      login_as(user)
      get help_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ayuda y soporte")
      expect(response.body).to include("Esto es beta cerrada")
      expect(response.body).to include("Repórtalo aquí")
    end

    it "renders for a user who has not completed onboarding (no redirect loop)" do
      onboarding_pending = create(:user, onboarded_at: nil)
      login_as_without_onboarding(onboarding_pending)
      # The redirect_to_onboarding before_action sends them to /welcome — that's expected
      get help_path
      expect(response).to redirect_to(welcome_path)
    end

    it "blocks anonymous users" do
      get help_path
      expect(response).to redirect_to(login_path)
    end
  end
end
