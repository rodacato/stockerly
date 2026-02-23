module RequestHelpers
  def login_as(user, password: "password123")
    ensure_onboarded(user)
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
