module RequestHelpers
  def login_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
