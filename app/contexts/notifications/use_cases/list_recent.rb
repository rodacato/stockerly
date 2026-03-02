module Notifications
  module UseCases
    class ListRecent < ApplicationUseCase
      def call(user:)
        notifications = user.notifications.recent
        unread_count  = user.notifications.unread.count

        Success({
          notifications: notifications,
          unread_count: unread_count
        })
      end
    end
  end
end
