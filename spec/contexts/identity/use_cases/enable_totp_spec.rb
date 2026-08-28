require "rails_helper"

RSpec.describe Identity::UseCases::EnableTotp do
  let(:user) { create(:user) }

  def begin_enrollment
    Identity::UseCases::BeginTotpEnrollment.call(user: user)
    user.reload
  end

  it "refuses when no enrollment was started" do
    result = described_class.call(user: user, code: "123456")

    expect(result).to be_failure
    expect(result.failure.first).to eq(:not_pending)
  end

  context "with a pending secret" do
    before { begin_enrollment }

    it "leaves the account unenrolled until a real code proves the app works" do
      expect(user.otp_enrolled?).to be false

      result = described_class.call(user: user, code: "000000")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:invalid_code)
      expect(user.reload.otp_enrolled?).to be false
    end

    it "enrolls on a valid code and returns ten codes, once" do
      result = described_class.call(user: user, code: ROTP::TOTP.new(user.otp_secret).now)

      expect(result).to be_success
      expect(result.value!.size).to eq(10)
      expect(user.reload.otp_enrolled?).to be true
      expect(user.otp_recovery_codes.unconsumed.count).to eq(10)
    end

    it "stores the recovery codes hashed, never in the clear" do
      codes = described_class.call(user: user, code: ROTP::TOTP.new(user.otp_secret).now).value!

      digests = user.otp_recovery_codes.pluck(:code_digest)
      expect(digests).not_to include(*codes)
      expect(digests).to all(start_with("$2a$"))
    end

    it "marks the enrolling code as used, so it cannot also open a session" do
      described_class.call(user: user, code: ROTP::TOTP.new(user.otp_secret).now)

      expect(user.reload.otp_last_used_at).to be_present
    end

    it "refuses a second enrollment on an account that already has one" do
      described_class.call(user: user, code: ROTP::TOTP.new(user.otp_secret).now)

      result = described_class.call(user: user, code: ROTP::TOTP.new(user.otp_secret).now)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:already_enrolled)
    end
  end
end
