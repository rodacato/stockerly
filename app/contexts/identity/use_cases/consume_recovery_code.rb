module Identity
  module UseCases
    # The way back in when the authenticator is gone. Each code works once.
    class ConsumeRecoveryCode < ApplicationUseCase
      def call(user:, code:)
        return Failure([ :not_enrolled, "Esta cuenta no tiene verificación en dos pasos." ]) unless user.otp_enrolled?

        normalized = Domain::RecoveryCodes.normalize(code)
        return Failure([ :invalid_code, "Ese código no es válido." ]) if normalized.blank?

        # BCrypt salts every digest, so there is nothing to look the code up
        # by: the unconsumed set is walked and each digest compared.
        record = user.otp_recovery_codes.unconsumed.find do |candidate|
          Domain::RecoveryCodes.matches?(normalized, candidate.code_digest)
        end
        return Failure([ :invalid_code, "Ese código no es válido." ]) if record.nil?

        record.update!(consumed_at: Time.current)
        Success(user)
      end
    end
  end
end
