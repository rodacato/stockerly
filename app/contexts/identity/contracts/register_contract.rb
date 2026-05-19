module Identity
  module Contracts
    class RegisterContract < ApplicationContract
      params do
        required(:full_name).filled(:string, min_size?: 2)
        required(:email).filled(:string)
        required(:password).filled(:string, min_size?: 8)
        required(:password_confirmation).filled(:string)
        required(:invite_code).filled(:string)
        required(:consents_data_processing).value(:bool)
      end

      rule(:email) do
        key.failure("must be a valid email") unless values[:email].match?(URI::MailTo::EMAIL_REGEXP)
      end

      rule(:password_confirmation) do
        key.failure("must match password") if values[:password] != values[:password_confirmation]
      end

      rule(:invite_code) do
        normalized = InviteCode.normalize(values[:invite_code])
        key.failure("must be 12 hex characters") unless normalized&.match?(/\A[a-f0-9]{12}\z/)
      end

      # Art. 8 LFPDPPP — datos patrimoniales (portfolio, trades) require
      # express, non-pre-checked consent at registration. Persisted as a
      # timestamp in `users.consents_data_processing_at`.
      rule(:consents_data_processing) do
        key.failure("debes autorizar expresamente el tratamiento de datos patrimoniales") unless values[:consents_data_processing] == true
      end
    end
  end
end
