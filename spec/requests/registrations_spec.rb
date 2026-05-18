require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /register" do
    it "renders the registration page" do
      get register_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Crea tu cuenta")
      expect(response.body).to include("consents_data_processing")
    end

    it "redirects to dashboard if already logged in" do
      user = create(:user, email: "existing@example.com", password: "password123")
      login_as(user)
      get register_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /register" do
    let(:invite) { create(:invite_code) }

    let(:valid_params) do
      {
        full_name: "Jane Doe",
        email: "jane@example.com",
        password: "password123",
        password_confirmation: "password123",
        invite_code: invite.code,
        consents_data_processing: "1"
      }
    end

    it "creates user and redirects to onboarding" do
      invite # trigger let-eager creation so the count delta only reflects the registrant
      expect {
        post register_path, params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response).to redirect_to(welcome_path)
    end

    it "rejects mismatched passwords" do
      post register_path, params: valid_params.merge(password_confirmation: "different")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must match password")
    end

    it "rejects short password" do
      post register_path, params: valid_params.merge(password: "short", password_confirmation: "short")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("size cannot be less than 8")
    end

    it "rejects duplicate email" do
      create(:user, email: "jane@example.com")
      post register_path, params: valid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("already been taken")
    end

    it "rejects missing invite code" do
      post register_path, params: valid_params.except(:invite_code)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects invalid invite code" do
      post register_path, params: valid_params.merge(invite_code: "deadbeef1234")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("inválido")
    end

    it "rejects already-used invite code" do
      used_invite = create(:invite_code, :used)
      post register_path, params: valid_params.merge(invite_code: used_invite.code)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("canjeado")
    end

    it "accepts hyphenated invite code" do
      post register_path, params: valid_params.merge(invite_code: invite.formatted_code)
      expect(response).to redirect_to(dashboard_path)
    end

    it "consumes invite code on successful registration" do
      post register_path, params: valid_params
      invite.reload
      expect(invite).to be_used
      expect(invite.used_by_user.email).to eq("jane@example.com")
    end

    it "repopulates fields on error" do
      post register_path, params: valid_params.merge(password: "short", password_confirmation: "short")
      expect(response.body).to include("Jane Doe")
      expect(response.body).to include("jane@example.com")
    end

    it "rejects registration when Art. 8 patrimonial consent is not granted" do
      # Form arrives without `consents_data_processing` when the checkbox is unchecked
      post register_path, params: valid_params.except(:consents_data_processing)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("autorizar")
    end

    it "persists the Art. 8 consent timestamp on successful registration" do
      post register_path, params: valid_params
      user = User.find_by(email: "jane@example.com")
      expect(user.consents_data_processing_at).to be_present
    end

    it "preserves the consent checkbox state when re-rendering after a non-consent validation error" do
      # User checked the consent box but mistyped the password confirmation.
      # The checkbox should still be checked on re-render — forcing them to
      # re-check it on every form error is bad UX.
      post register_path, params: valid_params.merge(password_confirmation: "different")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to match(/name="consents_data_processing"[^>]*checked/)
    end
  end
end
