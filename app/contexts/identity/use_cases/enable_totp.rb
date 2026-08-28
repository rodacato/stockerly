module Identity
  module UseCases
    # Finishes enrolment: the code proves the authenticator holds the pending
    # secret, and only then does the second factor start gating logins.
    #
    # Recovery codes are minted here rather than in a follow-up, because an
    # instance with one account and no support desk cannot afford the window
    # where TOTP is required and nothing can recover it (ADR-018).
    class EnableTotp < ApplicationUseCase
      def call(user:, code:)
        return Failure([ :not_pending, "No hay una alta de verificación en curso." ]) if user.otp_secret.blank?
        return Failure([ :already_enrolled, "La verificación en dos pasos ya está activa." ]) if user.otp_enrolled?

        used_at = Domain::Totp.verify(secret: user.otp_secret, code: code)
        return Failure([ :invalid_code, "Ese código no es válido. Revisa tu app de autenticación." ]) if used_at.nil?

        codes = nil
        user.transaction do
          user.update!(otp_enrolled_at: Time.current, otp_last_used_at: Time.at(used_at))
          codes = RegenerateRecoveryCodes.call(user: user)
        end

        Success(codes)
      end
    end
  end
end
