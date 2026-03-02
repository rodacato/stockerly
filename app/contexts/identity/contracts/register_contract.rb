module Identity
  module Contracts
    class RegisterContract < ApplicationContract
      params do
        required(:full_name).filled(:string, min_size?: 2)
        required(:email).filled(:string)
        required(:password).filled(:string, min_size?: 8)
        required(:password_confirmation).filled(:string)
      end

      rule(:email) do
        key.failure("must be a valid email") unless values[:email].match?(URI::MailTo::EMAIL_REGEXP)
      end

      rule(:password_confirmation) do
        key.failure("must match password") if values[:password] != values[:password_confirmation]
      end
    end
  end
end
