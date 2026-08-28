module Identity
  module Domain
    # Ten one-time codes, in the `7f2a-91c4` shape the artboard draws.
    #
    # They are the only way back into an instance whose owner lost the
    # authenticator, and there is no support desk behind them (ADR-018), so
    # they are generated from a CSPRNG and stored the way a password is.
    class RecoveryCodes
      COUNT = 10
      GROUP = 4

      class << self
        def generate(count: COUNT)
          Array.new(count) { "#{hex(GROUP)}-#{hex(GROUP)}" }
        end

        # Codes are shown once and typed back later, so a stray space or a
        # forgotten hyphen is the reader's most likely mistake, not an attack.
        def normalize(code)
          code.to_s.strip.downcase.delete("^a-f0-9")
        end

        def matches?(code, digest)
          BCrypt::Password.new(digest) == normalize(code)
        rescue BCrypt::Errors::InvalidHash
          false
        end

        def digest(code)
          BCrypt::Password.create(normalize(code)).to_s
        end

        private

        def hex(length)
          SecureRandom.hex(length / 2)
        end
      end
    end
  end
end
