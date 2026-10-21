module Notifications
  module UseCases
    # Delivers the morning summary to every install the user has subscribed.
    # It is a message the owner asked for, not an alert: it opens Hoy and does
    # not touch the badge count. Returns how many installs it reached.
    class PushDailyBrief < SimpleUseCase
      def call(user:, title:, body:)
        user.push_subscriptions.count do |subscription|
          Domain::WebPushDelivery.call(subscription: subscription, title: title, body: body,
                                       path: "/dashboard", badge_count: 0)
        end
      end
    end
  end
end
