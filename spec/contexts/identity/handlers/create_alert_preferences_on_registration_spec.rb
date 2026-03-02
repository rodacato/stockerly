require "rails_helper"

RSpec.describe Identity::CreateAlertPreferencesOnRegistration do
  let(:user) { create(:user) }

  it "creates alert preferences with defaults" do
    event = Identity::UserRegistered.new(user_id: user.id, email: user.email)

    expect { described_class.call(event) }.to change(AlertPreference, :count).by(1)
    prefs = user.reload.alert_preference
    expect(prefs.email_digest).to be true
    expect(prefs.browser_push).to be true
    expect(prefs.sms_notifications).to be false
  end

  it "does not create duplicate preferences" do
    create(:alert_preference, user: user)
    event = Identity::UserRegistered.new(user_id: user.id, email: user.email)

    expect { described_class.call(event) }.not_to change(AlertPreference, :count)
  end
end
