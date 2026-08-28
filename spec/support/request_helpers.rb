module RequestHelpers
  def login_as(user, password: "password123")
    ensure_onboarded(user)
    post login_path, params: { email: user.email, password: password }
    # An enrolled account is parked at the second factor by design, so the
    # helper finishes the real flow rather than reaching around it.
    complete_second_factor(user) if user.otp_enrolled?
  end

  def complete_second_factor(user)
    post two_factor_path, params: { code: ROTP::TOTP.new(user.otp_secret).now }
  end

  def login_as_without_onboarding(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end

  def ensure_onboarded(user)
    return if user.onboarded?

    user.update!(onboarded_at: Time.current)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
