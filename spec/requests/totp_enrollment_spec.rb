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

    it "gives a way back to Ajustes, where it was opened from" do
      get totp_enrollment_path

      expect(Capybara.string(response.body)).to have_css("header a[aria-label='Regresar'][href='#{settings_path}']")
    end

    it "renders inside the app shell once onboarded" do
      get totp_enrollment_path

      expect(response.body).to include(%(aria-label="#{I18n.t('nav.principal')}"))
    end

    # Mid-wizard, every app link bounces back to step 1, so the shell would
    # offer exits that all lead to the same place (D122, after D121).
    context "when opened from the setup wizard" do
      before { user.update!(onboarded_at: nil) }

      it "stays inside the wizard's frame, on its security step" do
        get totp_enrollment_path

        expect(response.body).not_to include(%(aria-label="#{I18n.t('nav.principal')}"))
        expect(response.body).to include("Paso 3 de 4")
      end

      it "leads on into the wizard, not to Ajustes" do
        get totp_enrollment_path

        expect(response.body).to include(%(href="#{onboarding_complete_path}"))
        expect(response.body).not_to include(%(href="#{settings_path}"))
      end

      it "shows the recovery codes inside the wizard too" do
        get totp_enrollment_path
        post totp_enrollment_path, params: { code: ROTP::TOTP.new(user.reload.otp_secret).now }
        get recovery_codes_path

        expect(response.body).not_to include(%(aria-label="#{I18n.t('nav.principal')}"))
        expect(response.body).to include("Paso 3 de 4")
        expect(response.body).to include(%(href="#{onboarding_complete_path}"))
      end
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
      follow_redirect!
      expect(response.body).to include("Podrás generar unos nuevos desde Ajustes.")
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

        expect(response.body).to include("te quedan 2 códigos")
      end

      # `recovery_codes_path` and `regenerate_recovery_codes_path` are the same
      # string — /two-factor/codes under two verbs — so only the method tells
      # the minting POST apart from the GET that shows a spent session.
      it "offers the POST that mints a fresh set" do
        get settings_path

        form = response.parsed_body.at_css("form[action='#{regenerate_recovery_codes_path}'][method='post']")

        expect(form).to be_present
        expect(form.at_css("input[name='_method']")).to be_nil
      end

      it "stops sending the reader to a screen with nothing left to show" do
        get settings_path

        expect(response.parsed_body.at_css("a[href='#{recovery_codes_path}']")).to be_nil
      end

      it "inflects the row down to the last code" do
        user.otp_recovery_codes.unconsumed.first.update!(consumed_at: Time.current)

        get settings_path

        expect(response.body).to include("te queda 1 código de recuperación")
      end
    end
  end
end
