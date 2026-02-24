require "rails_helper"

RSpec.describe SendVerificationEmailOnRegistration do
  describe ".async?" do
    it { expect(described_class.async?).to be true }
  end

  describe ".call" do
    let(:user) { create(:user) }

    it "logs verification URL for unverified user" do
      allow(Rails.logger).to receive(:info)

      described_class.call(user_id: user.id)

      expect(Rails.logger).to have_received(:info).with(/EMAIL VERIFICATION.*#{user.email}/)
    end

    it "does nothing when user not found" do
      expect { described_class.call(user_id: -1) }.not_to raise_error
    end

    it "does nothing when user is already email-verified" do
      user.update!(email_verified_at: Time.current)
      allow(Rails.logger).to receive(:info)

      described_class.call(user_id: user.id)

      expect(Rails.logger).not_to have_received(:info)
    end
  end
end
