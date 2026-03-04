require "rails_helper"

RSpec.describe "Setup", type: :request, setup_bypass: false do
  describe "GET /setup" do
    context "when no users exist" do
      it "renders the setup page" do
        get setup_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create Admin Account")
      end
    end

    context "when users already exist" do
      before { create(:user) }

      it "redirects to root" do
        get setup_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /setup" do
    let(:valid_params) do
      {
        full_name: "Admin User",
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    context "when no users exist" do
      it "creates admin and redirects to onboarding" do
        expect {
          post setup_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(User.last.admin?).to be true
        expect(response).to redirect_to(admin_onboarding_integrations_path)
      end

      it "bootstraps platform data" do
        post setup_path, params: valid_params
        expect(Integration.count).to eq(9)
        expect(MarketIndex.count).to eq(6)
        expect(FxRate.count).to eq(3)
      end
    end

    context "with invalid params" do
      it "renders errors" do
        post setup_path, params: valid_params.merge(email: "bad")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when users already exist" do
      before { create(:user) }

      it "redirects to root" do
        post setup_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "redirect_to_setup" do
    context "when no users exist" do
      it "redirects public pages to setup" do
        get root_path
        expect(response).to redirect_to(setup_path)
      end

      it "does not redirect health checks" do
        get rails_health_check_path
        expect(response).not_to redirect_to(setup_path)
      end
    end
  end
end
