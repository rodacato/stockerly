module Notifications
  module UseCases
    class UnsubscribeFromPush < SimpleUseCase
      def call(user:, endpoint:)
        user.push_subscriptions.where(endpoint: endpoint).destroy_all
      end
    end
  end
end
