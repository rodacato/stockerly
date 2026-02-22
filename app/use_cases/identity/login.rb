module Identity
  class Login < ApplicationUseCase
    def call(params:)
      attrs = yield validate(Identity::LoginContract, params)
      user  = yield find_user(attrs[:email])
      _     = yield verify_password(user, attrs[:password])
      _     = yield check_not_suspended(user)

      Success(user)
    end

    private

    def find_user(email)
      user = User.find_by(email: email.downcase.strip)
      user ? Success(user) : Failure([:invalid_credentials, "Invalid email or password."])
    end

    def verify_password(user, password)
      user.authenticate(password) ? Success(true) : Failure([:invalid_credentials, "Invalid email or password."])
    end

    def check_not_suspended(user)
      user.suspended? ? Failure([:suspended, "Your account has been suspended."]) : Success(true)
    end
  end
end
