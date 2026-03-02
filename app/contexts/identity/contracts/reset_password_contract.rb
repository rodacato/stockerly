module Identity
  module Contracts
    class ResetPasswordContract < ApplicationContract
      params do
        required(:password).filled(:string, min_size?: 8)
        required(:password_confirmation).filled(:string)
      end

      rule(:password_confirmation) do
        key.failure("must match password") if values[:password] != values[:password_confirmation]
      end
    end
  end
end
