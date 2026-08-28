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
