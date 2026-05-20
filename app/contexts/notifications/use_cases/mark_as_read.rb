module Notifications
  module UseCases
    class MarkAsRead < ApplicationUseCase
      def call(user:, notification_id: nil)
        if notification_id
          notification = user.notifications.find_by(id: notification_id)
          return Failure([ :not_found, "Notificación no encontrada" ]) unless notification

          notification.mark_as_read!
          Success(notification)
        else
          user.notifications.unread.update_all(read: true, read_at: Time.current)
          Success(:all_read)
        end
      end
    end
  end
end
