require "rails_helper"

RSpec.describe "Email verification banner", type: :request do
  describe "on authenticated pages" do
    it "shows banner when user email is not verified" do
      user = create(:user)
      login_as(user)

      get dashboard_path

      expect(response.body).to include("Please verify your email address")
      expect(response.body).to include(user.email)
    end

    it "does not show banner when user email is verified" do
      user = create(:user, :email_verified)
      login_as(user)

      get dashboard_path

      expect(response.body).not_to include("Please verify your email address")
    end
  end

  describe "on public pages" do
    it "does not show banner" do
      get root_path

      expect(response.body).not_to include("Please verify your email address")
    end
  end
end
