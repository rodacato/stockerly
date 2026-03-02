module Identity
  module UseCases
    class ResetPassword < ApplicationUseCase
      def call(token:, params:)
        attrs = yield validate(Contracts::ResetPasswordContract, params)
        user  = yield find_by_token(token)
        _     = yield update_password(user, attrs)

        user.remember_tokens.destroy_all

        Success(user)
      end

      private

      def find_by_token(token)
        user = User.find_by_password_reset_token(token)
        user ? Success(user) : Failure([ :invalid_token, "Invalid or expired reset link." ])
      end

      def update_password(user, attrs)
        if user.update(password: attrs[:password], password_confirmation: attrs[:password_confirmation])
          Success(user)
        else
          Failure([ :validation, user.errors.to_hash ])
        end
      end
    end
  end
end
