module Identity
  module Contracts
    class VerifyEmailContract < ApplicationContract
      params do
        required(:token).filled(:string)
      end
    end
  end
end
