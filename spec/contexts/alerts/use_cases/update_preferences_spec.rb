require "rails_helper"

RSpec.describe Alerts::UpdatePreferences do
  let(:user) { create(:user) }

  describe ".call" do
    it "creates and updates alert preference" do
      result = described_class.call(user: user, params: { email_digest: true, browser_push: false, sms_notifications: true })

      expect(result).to be_success
      pref = result.value!
      expect(pref.email_digest).to be true
      expect(pref.browser_push).to be false
      expect(pref.sms_notifications).to be true
    end

    it "updates existing preference" do
      create(:alert_preference, user: user, email_digest: false)
      result = described_class.call(user: user, params: { email_digest: true })

      expect(result).to be_success
      expect(result.value!.email_digest).to be true
    end

    it "ignores params not in the allowed slice" do
      result = described_class.call(user: user, params: { email_digest: true, unknown_param: "hack" })

      expect(result).to be_success
      expect(result.value!.email_digest).to be true
    end
  end
end
