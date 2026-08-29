module Notifications
  module UseCases
    class SubscribeToPush < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Contracts::SubscribeToPushContract, params)

        # A browser re-issues the same endpoint with fresh keys after it
        # rotates them, so the endpoint is the identity, not the row.
        subscription = PushSubscription.find_or_initialize_by(endpoint: attrs[:endpoint])
        subscription.update!(user: user, p256dh_key: attrs[:p256dh_key], auth_key: attrs[:auth_key])

        Success(subscription)
      end
    end
  end
end
