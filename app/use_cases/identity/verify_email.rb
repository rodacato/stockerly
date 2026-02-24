module Identity
  class VerifyEmail < ApplicationUseCase
    def call(params:)
      attrs = yield validate(Identity::VerifyEmailContract, params)
      user  = yield find_by_token(attrs[:token])
      _     = yield mark_verified(user)
      _     = yield publish(EmailVerified.new(user_id: user.id, email: user.email))

      Success(user)
    end

    private

    def find_by_token(token)
      user = User.find_by_token_for(:email_verification, token)
      user ? Success(user) : Failure([ :invalid_token, "Invalid or expired verification link." ])
    end

    def mark_verified(user)
      return Success(user) if user.email_verified?

      if user.update(email_verified_at: Time.current)
        Success(user)
      else
        Failure([ :update_failed, "Could not verify email." ])
      end
    end
  end
end
