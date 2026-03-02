module Notifications
  class BroadcastNotification
  def self.call(event)
    user_id         = event.is_a?(Hash) ? event[:user_id] : event.user_id
    notification_id = event.is_a?(Hash) ? event[:notification_id] : event.notification_id

    notification = Notification.find_by(id: notification_id)
    return unless notification

    unread_count = Notification.where(user_id: user_id, read: false).count

    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_#{user_id}",
      target: "notification_badge",
      partial: "shared/notification_badge",
      locals: { unread_count: unread_count }
    )

    Turbo::StreamsChannel.broadcast_prepend_to(
      "notifications_#{user_id}",
      target: "notifications_list",
      partial: "shared/notification_item",
      locals: { notification: notification }
    )
  end
  end
end
