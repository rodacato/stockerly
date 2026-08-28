require "rails_helper"

RSpec.describe "Two-factor login", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "password123" }
  let(:user) { create(:user, :with_totp, password: password, onboarded_at: Time.current) }
  let(:valid_code) { ROTP::TOTP.new(user.otp_secret).now }

  def submit_password
    post login_path, params: { email: user.email, password: password }
  end

  describe "the password step" do
    it "does not sign the user in — it parks the login and asks for the code" do
      submit_password

      expect(response).to redirect_to(two_factor_path)
      expect(session[:user_id]).to be_nil
      expect(session[:pending_user_id]).to eq(user.id)
    end

    it "still signs in an account that never enrolled" do
      plain = create(:user, password: password, onboarded_at: Time.current)
      post login_path, params: { email: plain.email, password: password }

      expect(response).to redirect_to(dashboard_path)
      expect(session[:user_id]).to eq(plain.id)
    end
  end

  # The DoD's negative case, and the reason the design withholds session[:user_id]
  # rather than guarding routes: there is no identity to guard.
  describe "a half-authenticated session" do
    before { submit_password }

    it "reaches no authenticated route" do
      [ dashboard_path, assets_path, settings_path, portfolio_path, alerts_path ].each do |path|
        get path
        expect(response).to redirect_to(login_path), "#{path} was reachable before the second factor"
      end
    end

    it "cannot be promoted by asking for the dashboard repeatedly" do
      3.times { get dashboard_path }
      expect(session[:user_id]).to be_nil
    end
  end

  describe "the code step" do
    before { submit_password }

    it "signs in on a valid code" do
      post two_factor_path, params: { code: valid_code }

      expect(response).to redirect_to(dashboard_path)
      expect(session[:user_id]).to eq(user.id)
      expect(session[:pending_user_id]).to be_nil
    end

    it "refuses a wrong code and keeps the login parked" do
      post two_factor_path, params: { code: "000000" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
      expect(session[:pending_user_id]).to eq(user.id)
    end

    # ROTP accepts a code twice inside its 30s window unless told otherwise.
    it "refuses the same code a second time" do
      post two_factor_path, params: { code: valid_code }
      expect(session[:user_id]).to eq(user.id)

      delete logout_path
      submit_password
      post two_factor_path, params: { code: valid_code }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
    end

    it "sends an expired pending login back to the password" do
      travel_to(TwoFactorController::PENDING_TIMEOUT.from_now + 1.minute) do
        post two_factor_path, params: { code: valid_code }

        expect(response).to redirect_to(login_path)
        expect(session[:pending_user_id]).to be_nil
      end
    end
  end

  describe "the recovery path" do
    before { submit_password }

    it "signs in on an unused code and spends it" do
      expect { post recovery_code_path, params: { code: "7f2a-91c4" } }
        .to change { user.otp_recovery_codes.unconsumed.count }.from(2).to(1)

      expect(response).to redirect_to(dashboard_path)
      expect(session[:user_id]).to eq(user.id)
    end

    it "accepts the code as it was typed, spacing and case included" do
      post recovery_code_path, params: { code: "  7F2A 91C4 " }
      expect(session[:user_id]).to eq(user.id)
    end

    it "refuses a code that was already spent" do
      post recovery_code_path, params: { code: "7f2a-91c4" }
      delete logout_path
      submit_password

      post recovery_code_path, params: { code: "7f2a-91c4" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
    end

    it "refuses a code that was never issued" do
      post recovery_code_path, params: { code: "dead-beef" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "reaching the screens without a pending login" do
    it "bounces to the password" do
      [ two_factor_path, recovery_code_path ].each do |path|
        get path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
