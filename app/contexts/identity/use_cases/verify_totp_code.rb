module Identity
  module UseCases
    # The login's second step, authenticator path.
    class VerifyTotpCode < ApplicationUseCase
      def call(user:, code:)
        return Failure([ :not_enrolled, "Esta cuenta no tiene verificación en dos pasos." ]) unless user.otp_enrolled?

        used_at = Domain::Totp.verify(secret: user.otp_secret, code: code, after: user.otp_last_used_at)
        return Failure([ :invalid_code, "Ese código no es válido." ]) if used_at.nil?

        # Recording the window the code came from is what makes a second
        # submission of the same code fail rather than pass.
        user.update!(otp_last_used_at: Time.at(used_at))
        Success(user)
      end
    end
  end
end
