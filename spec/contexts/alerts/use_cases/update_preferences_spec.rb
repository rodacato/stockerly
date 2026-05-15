require "rails_helper"

RSpec.describe Alerts::UseCases::UpdatePreferences do
  let(:user) { create(:user) }

  describe ".call" do
    it "creates and updates the preference when none exists" do
      pref = described_class.call(user: user, params: { email_digest: true, browser_push: false, sms_notifications: true })

      expect(pref.email_digest).to be true
      expect(pref.browser_push).to be false
      expect(pref.sms_notifications).to be true
    end

    it "updates an existing preference in place" do
      create(:alert_preference, user: user, email_digest: false)
      pref = described_class.call(user: user, params: { email_digest: true })

      expect(pref.email_digest).to be true
    end

    it "ignores params not in the allowed slice (mass-assignment guard)" do
      pref = described_class.call(user: user, params: { email_digest: true, unknown_param: "hack" })
      expect(pref.email_digest).to be true
    end
  end
end
