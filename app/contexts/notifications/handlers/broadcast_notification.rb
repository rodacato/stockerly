module Notifications
  module Handlers
    class BroadcastNotification
      def self.call(event)
        user_id         = event.is_a?(Hash) ? event[:user_id] : event.user_id
        notification_id = event.is_a?(Hash) ? event[:notification_id] : event.notification_id

        notification = Notification.find_by(id: notification_id)
        return unless notification

        unread_count = Notification.where(user_id: user_id, read: false).count

        # `targets`, not `target`: both top bars are in the DOM at once and CSS
        # picks which one shows, so the badge has to update in both.
        Turbo::StreamsChannel.broadcast_replace_to(
          "notifications_#{user_id}",
          targets: ".js-notification-badge",
          partial: "components/notification_badge",
          locals: { unread_count: unread_count }
        )

        Turbo::StreamsChannel.broadcast_prepend_to(
          "notifications_#{user_id}",
          target: "notifications_list",
          partial: "notifications/notification_row",
          locals: { notification: notification }
        )
      end
    end
  end
end
