module Notifications
  class MarkAsRead < ApplicationUseCase
    def call(user:, notification_id: nil)
      if notification_id
        notification = user.notifications.find_by(id: notification_id)
        return Failure([ :not_found, "Notification not found" ]) unless notification

        notification.mark_as_read!
        Success(notification)
      else
        user.notifications.unread.update_all(read: true)
        Success(:all_read)
      end
    end
  end
end
