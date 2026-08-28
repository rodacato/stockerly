module Identity
  module UseCases
    # Replaces every code, used or not. Returns the plaintext set — the only
    # moment it exists — so the caller can show it once and then forget it.
    class RegenerateRecoveryCodes < SimpleUseCase
      def call(user:)
        codes = Domain::RecoveryCodes.generate

        user.transaction do
          user.otp_recovery_codes.delete_all
          codes.each { |code| user.otp_recovery_codes.create!(code_digest: Domain::RecoveryCodes.digest(code)) }
        end

        codes
      end
    end
  end
end
