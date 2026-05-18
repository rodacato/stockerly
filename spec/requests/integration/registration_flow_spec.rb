require "rails_helper"

RSpec.describe "Registration flow", type: :request do
  before do
    # Re-subscribe event handlers needed for registration flow
    EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreatePortfolioOnRegistration)
    EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreateAlertPreferencesOnRegistration)
  end

  it "creates portfolio and alert preferences on registration" do
    invite = create(:invite_code)
    post register_path, params: {
      full_name: "Jane Doe",
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123",
      invite_code: invite.code,
      consents_data_processing: "1"
    }

    user = User.find_by(email: "jane@example.com")
    expect(user).to be_present
    expect(user.portfolio).to be_present
    expect(user.alert_preference).to be_present
    expect(user.alert_preference.email_digest).to be true
  end

  it "redirects to dashboard after registration" do
    invite = create(:invite_code)
    post register_path, params: {
      full_name: "Jane Doe",
      email: "jane2@example.com",
      password: "password123",
      password_confirmation: "password123",
      invite_code: invite.code,
      consents_data_processing: "1"
    }
    expect(response).to redirect_to(dashboard_path)
  end

  it "new user is redirected to onboarding from dashboard" do
    invite = create(:invite_code)
    post register_path, params: {
      full_name: "Jane Doe",
      email: "jane3@example.com",
      password: "password123",
      password_confirmation: "password123",
      invite_code: invite.code,
      consents_data_processing: "1"
    }
    follow_redirect!
    expect(response).to redirect_to(welcome_path)
  end
end
