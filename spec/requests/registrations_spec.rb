require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /register" do
    it "renders the registration page" do
      get register_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your account")
    end
  end

  describe "POST /register" do
    let(:valid_params) do
      {
        full_name: "Jane Doe",
        email: "jane@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    it "creates user and logs in" do
      expect {
        post register_path, params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Welcome to TrendStocker")
    end

    it "rejects mismatched passwords" do
      post register_path, params: valid_params.merge(password_confirmation: "different")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("doesn&#39;t match Password")
    end

    it "rejects short password" do
      post register_path, params: valid_params.merge(password: "short", password_confirmation: "short")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("too short")
    end

    it "rejects duplicate email" do
      create(:user, email: "jane@example.com")
      post register_path, params: valid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("already been taken")
    end

    it "repopulates fields on error" do
      post register_path, params: valid_params.merge(password: "short", password_confirmation: "short")
      expect(response.body).to include("Jane Doe")
      expect(response.body).to include("jane@example.com")
    end
  end
end
