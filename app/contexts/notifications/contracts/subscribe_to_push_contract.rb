module Notifications
  module Contracts
    class SubscribeToPushContract < ApplicationContract
      params do
        required(:endpoint).filled(:string)
        required(:p256dh_key).filled(:string)
        required(:auth_key).filled(:string)
      end

      rule(:endpoint) do
        key.failure("must be an https endpoint") unless value.start_with?("https://")
      end
    end
  end
end
