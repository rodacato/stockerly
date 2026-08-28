require "rails_helper"

RSpec.describe "Onboarding · the security step", type: :request do
  let(:user) { create(:user) }

  before { login_as_without_onboarding(user) }

  it "is step 3 of 4, not step 1" do
    get onboarding_security_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Paso 3 de 4")
    expect(OnboardingController::STEPS).to eq(4)
  end

  it "sits between the assets step and the summary" do
    post onboarding_assets_path, params: { symbols: [] }

    expect(response).to redirect_to(onboarding_security_path)
  end

  # D52: the step offers and lets the reader skip. A wizard that blocks first
  # boot on a phone the reader may not have in hand is the trap.
  it "offers enrollment and a way past it" do
    get onboarding_security_path

    expect(response.body).to include(totp_enrollment_path)
    expect(response.body).to include(onboarding_complete_path)
  end

  it "does not enroll anything by itself" do
    get onboarding_security_path

    expect(user.reload.otp_enrolled?).to be false
  end
end

RSpec.describe "Onboarding · enrolling from inside the wizard", type: :request do
  let(:user) { create(:user) }

  before { login_as_without_onboarding(user) }

  # The step's whole point is the button. An account mid-wizard is not
  # `onboarded?`, so AuthenticatedController's guard would bounce it back to
  # step 1 — the step would lead to the beginning of the wizard it is inside.
  it "reaches the enrollment screen instead of being thrown back to step 1" do
    get totp_enrollment_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<svg")
  end

  # Asserting on the CTA rather than on the page: the app layout renders an
  # "Ajustes" tab, so `not_to include(settings_path)` would fail for a reason
  # that has nothing to do with where the button goes.
  def cta_href(label)
    Nokogiri::HTML(response.body).css("a").find { |a| a.text.strip == label }&.[](:href)
  end

  it "returns to the wizard's summary, not to Ajustes, once the codes are shown" do
    get totp_enrollment_path
    post totp_enrollment_path, params: { code: ROTP::TOTP.new(user.reload.otp_secret).now }
    follow_redirect!

    expect(cta_href("Ya los guardé, continuar")).to eq(onboarding_complete_path)
  end

  it "offers the skip back into the wizard, not into Ajustes" do
    get totp_enrollment_path

    expect(cta_href("Ahora no")).to eq(onboarding_complete_path)
  end
end
