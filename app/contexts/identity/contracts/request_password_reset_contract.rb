module Identity
  module Contracts
    class RequestPasswordResetContract < ApplicationContract
      params do
        required(:email).filled(:string)
      end
    end
  end
end
