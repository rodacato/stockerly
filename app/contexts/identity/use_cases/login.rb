module Identity
  module UseCases
    class Login < ApplicationUseCase
      def call(params:)
        attrs = yield validate(Contracts::LoginContract, params)
        user  = yield find_user(attrs[:email])
        _     = yield verify_password(user, attrs[:password])

        Success(user)
      end

      private

      def find_user(email)
        user = User.find_by(email: email.downcase.strip)
        user ? Success(user) : Failure([ :invalid_credentials, "Correo o contraseña inválidos." ])
      end

      def verify_password(user, password)
        user.authenticate(password) ? Success(true) : Failure([ :invalid_credentials, "Correo o contraseña inválidos." ])
      end
    end
  end
end
