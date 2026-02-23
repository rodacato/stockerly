require "rails_helper"

RSpec.describe RememberToken, type: :model do
  describe ".active" do
    it "returns only non-expired tokens" do
      user = create(:user)
      active_token = create(:remember_token, user: user, expires_at: 1.day.from_now)
      create(:remember_token, :expired, user: user)

      expect(RememberToken.active).to eq([ active_token ])
    end
  end

  describe "#expired?" do
    it "returns false for future expiry" do
      token = build(:remember_token, expires_at: 1.day.from_now)
      expect(token.expired?).to be false
    end

    it "returns true for past expiry" do
      token = build(:remember_token, expires_at: 1.day.ago)
      expect(token.expired?).to be true
    end
  end

  describe "#touch_last_used!" do
    it "updates last_used_at" do
      token = create(:remember_token)
      expect { token.touch_last_used! }.to change { token.reload.last_used_at }
    end
  end

  describe ".generate" do
    let(:user) { create(:user) }

    it "creates a token and returns raw value" do
      token_record, raw_token = RememberToken.generate(user, ip_address: "1.2.3.4", user_agent: "Test")

      expect(token_record).to be_persisted
      expect(raw_token).to be_present
      expect(token_record.token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(token_record.expires_at).to be_within(1.second).of(30.days.from_now)
      expect(token_record.ip_address).to eq("1.2.3.4")
    end

    it "truncates long user agents" do
      long_agent = "A" * 500
      token_record, _ = RememberToken.generate(user, ip_address: "1.2.3.4", user_agent: long_agent)
      expect(token_record.user_agent.length).to eq(255)
    end
  end
end
