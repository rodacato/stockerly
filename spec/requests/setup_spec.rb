require "rails_helper"

RSpec.describe "Setup", type: :request, setup_bypass: false do
  describe "GET /setup" do
    context "when no users exist" do
      it "renders the setup page" do
        get setup_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Crea tu cuenta")
        # D5: one account, so no "admin" anywhere the person can read it.
        expect(response.body).not_to match(/admin/i)
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
        expect(response).to redirect_to(onboarding_integrations_path)
      end

      it "bootstraps platform data" do
        post setup_path, params: valid_params
        expect(Integration.count).to eq(MarketData::Domain::ProviderDefaults::ALL.size)
        expect(MarketIndex.count).to eq(6)
        expect(FxRate.count).to eq(0)
      end
    end

    context "with invalid params" do
      it "renders errors" do
        post setup_path, params: valid_params.merge(email: "bad")
        expect(response).to have_http_status(:unprocessable_content)
      end

      # ADR-011: the list is the first thing a self-hoster reads, and it used to
      # answer in English on both halves — `Email must be a valid email`.
      it "names the field and states the failure in es-MX" do
        post setup_path, params: valid_params.merge(email: "bad", password_confirmation: "otra")

        expect(response.body).to include("El correo debe ser un correo válido")
        expect(response.body).to include("La confirmación no coincide con la contraseña")
      end

      it "keeps the name and email the reader already typed, but never the password" do
        post setup_path, params: valid_params.merge(email: "bad")

        expect(response.body).to include(%(value="#{valid_params[:full_name]}"))
        expect(response.body).to include(%(value="bad"))
        expect(response.body).not_to include(%(value="#{valid_params[:password]}"))
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
        # / now route-redirects to /login; the setup check fires at the SessionsController
        # before_action, which sends the user on to /setup if no users exist.
        get login_path
        expect(response).to redirect_to(setup_path)
      end

      it "does not redirect health checks" do
        get rails_health_check_path
        expect(response).not_to redirect_to(setup_path)
      end
    end
  end
end
