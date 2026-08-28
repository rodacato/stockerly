module Identity
  module Domain
    # The whole surface the app needs from ROTP, in one place, so no controller
    # or use case reaches for the library directly (ADR-019: the dependency is
    # ours to swap, not scattered).
    class Totp
      ISSUER = "Stockerly".freeze

      # One step behind and one ahead, which covers a phone whose clock has
      # drifted without widening the window enough to matter.
      DRIFT = 30

      class << self
        def generate_secret
          ROTP::Base32.random
        end

        def provisioning_uri(secret:, email:)
          ROTP::TOTP.new(secret, issuer: ISSUER).provisioning_uri(email)
        end

        # `after` is what stops a replay: ROTP will not accept a code from a
        # window at or before the one already used. Returns the timestamp the
        # code belongs to, or nil when it does not verify.
        def verify(secret:, code:, after: nil)
          return nil if secret.blank? || code.blank?

          ROTP::TOTP.new(secret).verify(code.to_s.strip.delete(" "),
                                        drift_behind: DRIFT, drift_ahead: DRIFT, after: after)
        end

        # The artboard prints the secret in four-character groups so it can be
        # typed by hand when the camera is not an option.
        def format_for_display(secret)
          secret.to_s.scan(/.{1,4}/).join(" ")
        end
      end
    end
  end
end
