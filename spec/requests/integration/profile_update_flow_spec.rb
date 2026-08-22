require "rails_helper"

RSpec.describe "Profile update flow", type: :request do
  let!(:user) { create(:user, full_name: "John Doe", email: "john@example.com", password: "password123") }

  before do
    login_as(user)
  end

  it "updates name and reflects on profile page" do
    patch profile_path, params: { profile: { full_name: "Jane Smith", email: user.email } }
    expect(response).to redirect_to(profile_path)

    follow_redirect!
    expect(response.body).to include("Jane Smith")
    expect(user.reload.full_name).to eq("Jane Smith")
  end

  it "changes password" do
    patch change_password_path, params: {
      password_change: {
        current_password: "password123",
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
    }
    expect(response).to redirect_to(profile_path)
    expect(user.reload.authenticate("newpassword456")).to be_truthy
  end
end
