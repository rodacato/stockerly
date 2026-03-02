require "rails_helper"

RSpec.describe Identity::VerifyEmail do
  include ActiveSupport::Testing::TimeHelpers

  describe ".call" do
    let(:user) { create(:user) }
    let(:token) { user.generate_token_for(:email_verification) }

    it "verifies user and returns Success with valid token" do
      result = described_class.call(params: { token: token })

      expect(result).to be_success
      expect(result.value!).to eq(user)
      expect(user.reload.email_verified_at).to be_present
    end

    it "publishes EmailVerified event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(Identity::EmailVerified))

      described_class.call(params: { token: token })
    end

    it "returns Failure for invalid token" do
      result = described_class.call(params: { token: "invalid-token" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:invalid_token)
    end

    it "returns Failure for expired token" do
      token_value = token
      travel_to 25.hours.from_now do
        result = described_class.call(params: { token: token_value })

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:invalid_token)
      end
    end

    it "succeeds idempotently if user is already verified" do
      user.update!(email_verified_at: 1.day.ago)

      result = described_class.call(params: { token: token })

      expect(result).to be_success
      expect(result.value!).to eq(user)
    end

    it "returns Failure for empty token" do
      result = described_class.call(params: { token: "" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
