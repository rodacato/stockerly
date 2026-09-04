module Notifications
  module UseCases
    # Returns the notification, or nil when there is nobody to notify or the
    # record will not save. Every caller is a job or handler that carries on
    # either way, so nil is the whole vocabulary the callers ever read.
    class CreateNotification < SimpleUseCase
      def call(user_id:, title:, body: nil, notification_type: :system, notifiable: nil)
        user = User.find_by(id: user_id)
        return unless user

        notification = user.notifications.create!(
          title: title,
          body: body,
          notification_type: notification_type,
          notifiable: notifiable,
          read: false
        )

        EventBus.publish(Events::NotificationCreated.new(
          notification_id: notification.id,
          user_id: user.id,
          title: title
        ))

        notification
      rescue ActiveRecord::RecordInvalid
        nil
      end
    end
  end
end
