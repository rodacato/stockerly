require "rails_helper"

RSpec.describe Admin::BaseController, type: :controller do
  controller(Admin::BaseController) do
    def index
      render plain: "admin content"
    end
  end

  before do
    routes.draw { get "index", to: "admin/base#index" }
  end

  describe "require_admin" do
    context "when not logged in" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in as regular user" do
      let(:user) { create(:user, onboarded_at: Time.current) }

      before do
        session[:user_id] = user.id
      end

      it "redirects to root with alert" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end

    context "when logged in as admin" do
      let(:admin) { create(:user, :admin, onboarded_at: Time.current) }

      before do
        session[:user_id] = admin.id
      end

      it "allows access" do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("admin content")
      end
    end
  end
end
