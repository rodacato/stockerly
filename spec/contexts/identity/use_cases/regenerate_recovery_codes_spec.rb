require "rails_helper"

RSpec.describe Identity::UseCases::RegenerateRecoveryCodes do
  let(:user) { create(:user, :with_totp) }

  it "replaces every code, spent or not" do
    user.otp_recovery_codes.first.update!(consumed_at: Time.current)

    codes = described_class.call(user: user)

    expect(codes.size).to eq(10)
    expect(user.reload.otp_recovery_codes.count).to eq(10)
    expect(user.otp_recovery_codes.unconsumed.count).to eq(10)
  end

  it "makes the old codes stop working" do
    described_class.call(user: user)

    result = Identity::UseCases::ConsumeRecoveryCode.call(user: user, code: "7f2a-91c4")

    expect(result).to be_failure
  end
end
