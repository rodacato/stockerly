require "rails_helper"

RSpec.describe "TOTP enrollment", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }

  before { login_as(user) }

  describe "GET /two-factor/setup" do
    it "shows a QR and the key to type by hand when the camera is not an option" do
      get totp_enrollment_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<svg")
      expect(user.reload.otp_secret).to be_present
      expect(response.body).to include(Identity::Domain::Totp.format_for_display(user.otp_secret))
    end

    it "leaves the account unenrolled until a code is verified" do
      get totp_enrollment_path

      expect(user.reload.otp_enrolled?).to be false
    end

    context "when the account is already enrolled" do
      let(:user) { create(:user, :with_totp, onboarded_at: Time.current) }

      it "sends it away rather than offering a second secret" do
        get totp_enrollment_path

        expect(response).to redirect_to(settings_path)
      end
    end
  end

  describe "POST /two-factor/setup" do
    before { get totp_enrollment_path }

    it "enrolls on a valid code and sends the reader to the codes, once" do
      post totp_enrollment_path, params: { code: ROTP::TOTP.new(user.reload.otp_secret).now }

      expect(response).to redirect_to(recovery_codes_path)
      expect(user.reload.otp_enrolled?).to be true

      follow_redirect!
      expect(response.body).to include("Guarda tus códigos de recuperación")
      expect(response.body.scan(/[0-9a-f]{4}-[0-9a-f]{4}/).uniq.size).to eq(10)
    end

    it "re-renders with the QR intact on a wrong code" do
      post totp_enrollment_path, params: { code: "000000" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("<svg")
      expect(user.reload.otp_enrolled?).to be false
    end
  end

  describe "GET /two-factor/codes" do
    it "refuses to show the codes a second time" do
      get totp_enrollment_path
      post totp_enrollment_path, params: { code: ROTP::TOTP.new(user.reload.otp_secret).now }
      get recovery_codes_path

      get recovery_codes_path

      expect(response).to redirect_to(settings_path)
    end
  end

  describe "POST /two-factor/codes" do
    let(:user) { create(:user, :with_totp, onboarded_at: Time.current) }

    it "mints a fresh set and retires the old one" do
      post regenerate_recovery_codes_path

      expect(response).to redirect_to(recovery_codes_path)
      expect(user.reload.otp_recovery_codes.unconsumed.count).to eq(10)
      expect(Identity::UseCases::ConsumeRecoveryCode.call(user: user, code: "7f2a-91c4")).to be_failure
    end

    context "when the account never enrolled" do
      let(:user) { create(:user, onboarded_at: Time.current) }

      it "is not offered" do
        post regenerate_recovery_codes_path

        expect(response).to redirect_to(totp_enrollment_path)
      end
    end
  end

  describe "the Ajustes hub" do
    it "offers enrollment while the factor is off" do
      get settings_path

      expect(response.body).to include(totp_enrollment_path)
    end

    context "once enrolled" do
      let(:user) { create(:user, :with_totp, onboarded_at: Time.current) }

      it "reports the state and how many codes are left" do
        get settings_path

        expect(response.body).to include(recovery_codes_path)
        expect(response.body).to include("te quedan 2 códigos")
      end
    end
  end
end
