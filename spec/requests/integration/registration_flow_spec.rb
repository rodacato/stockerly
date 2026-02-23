require "rails_helper"

RSpec.describe "Registration flow", type: :request do
  before do
    # Re-subscribe event handlers needed for registration flow
    EventBus.subscribe(UserRegistered, CreatePortfolioOnRegistration)
    EventBus.subscribe(UserRegistered, CreateAlertPreferencesOnRegistration)
  end

  it "creates portfolio and alert preferences on registration" do
    post register_path, params: {
      full_name: "Jane Doe",
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123"
    }

    user = User.find_by(email: "jane@example.com")
    expect(user).to be_present
    expect(user.portfolio).to be_present
    expect(user.alert_preference).to be_present
    expect(user.alert_preference.email_digest).to be true
  end

  it "redirects to dashboard after registration" do
    post register_path, params: {
      full_name: "Jane Doe",
      email: "jane2@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
    expect(response).to redirect_to(dashboard_path)
  end

  it "new user is redirected to onboarding from dashboard" do
    post register_path, params: {
      full_name: "Jane Doe",
      email: "jane3@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
    follow_redirect!
    expect(response).to redirect_to(onboarding_step1_path)
  end
end
