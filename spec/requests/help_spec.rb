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
      expect(response.body).to include(I18n.t("shared.welcome_body.bug_enlace"))
    end

    # /report-bug was a hosted-beta surface: it mailed support@notdefined.dev
    # from whatever instance rendered it, and ADR-0010 dropped that audience.
    # A bug goes to the public tracker now, which the owner of any instance
    # can actually read.
    it "sends a bug to the issue tracker rather than to somebody else's inbox" do
      login_as(user)
      get help_path

      expect(response.body).to include(Stockerly::ISSUES_URL)
      expect(response.body).not_to include("/report-bug")
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
