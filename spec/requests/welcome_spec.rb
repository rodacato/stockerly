require "rails_helper"

RSpec.describe "Welcome", type: :request do
  # :admin, not the factory default. CreateFirstAdmin is the only path that
  # makes a user and it hard-codes role: :admin, so a `role: :user` fixture
  # describes a state this app cannot reach — which is how this spec used to
  # pass while /welcome had no route leading to it.
  let(:user) { create(:user, :admin, onboarded_at: nil) }

  describe "GET /welcome" do
    it "renders for a logged-in user who has not completed onboarding" do
      login_as_without_onboarding(user)
      get welcome_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hola")
      expect(response.body).to include("Tu tracker personal de inversiones")
      expect(response.body).to include("Software en desarrollo")
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

  describe "arriving here" do
    it "is where the wizard sends you when it finishes" do
      login_as_without_onboarding(user)

      post onboarding_launch_path

      expect(response).to redirect_to(welcome_path)
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
