module Notifications
  module UseCases
    class CreateNotification < ApplicationUseCase
      def call(user_id:, title:, body: nil, notification_type: :system, notifiable: nil)
        user = User.find_by(id: user_id)
        return Failure([ :not_found, "User not found" ]) unless user

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

        Success(notification)
      rescue ActiveRecord::RecordInvalid => e
        Failure([ :validation, e.record.errors.to_hash ])
      end
    end
  end
end
