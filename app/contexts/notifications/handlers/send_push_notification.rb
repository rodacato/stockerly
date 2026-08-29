module Notifications
  module Handlers
    # Pushes to the installed app on the same terms as the urgent email: a
    # fired rule is an interruption, an earnings or maturity date is not —
    # those ride the digest.
    class SendPushNotification
      def self.async? = true

      def self.call(event)
        notification_id = event.is_a?(Hash) ? event[:notification_id] : event.notification_id
        notification = Notification.find_by(id: notification_id)
        return unless notification&.alert_triggered?

        user = notification.user
        return unless user&.alert_preference&.push

        deliver_to_each_install(user, notification)
      end

      def self.deliver_to_each_install(user, notification)
        badge_count = Notification.where(user_id: user.id, read: false).count

        user.push_subscriptions.find_each do |subscription|
          Domain::WebPushDelivery.call(
            subscription: subscription,
            title: notification.title,
            body: notification.body.presence || notification.title,
            path: "/notifications",
            badge_count: badge_count
          )
        end
      end
      private_class_method :deliver_to_each_install
    end
  end
end
