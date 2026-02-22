require "rails_helper"

RSpec.describe AlertPreference, type: :model do
  subject(:pref) { build(:alert_preference) }

  describe "validations" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it "belongs to user" do
      expect(pref.user).to be_present
    end
  end

  describe "defaults" do
    it "has browser_push true by default" do
      pref = AlertPreference.new
      expect(pref.browser_push).to be true
    end

    it "has email_digest true by default" do
      pref = AlertPreference.new
      expect(pref.email_digest).to be true
    end

    it "has sms_notifications false by default" do
      pref = AlertPreference.new
      expect(pref.sms_notifications).to be false
    end
  end
end
