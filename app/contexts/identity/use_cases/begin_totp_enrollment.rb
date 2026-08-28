module Identity
  module UseCases
    # Hands back a secret and the QR payload for it. The secret is stored on
    # the user but `otp_enrolled_at` stays nil, so the account keeps logging in
    # with the password alone until a first valid code proves the authenticator
    # actually works. Re-running replaces the pending secret, which is what
    # "I scanned it on the wrong phone" needs.
    class BeginTotpEnrollment < SimpleUseCase
      def call(user:)
        secret = Domain::Totp.generate_secret
        user.update!(otp_secret: secret)

        { secret: secret,
          formatted_secret: Domain::Totp.format_for_display(secret),
          provisioning_uri: Domain::Totp.provisioning_uri(secret: secret, email: user.email) }
      end
    end
  end
end
