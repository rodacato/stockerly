module Notifications
  module UseCases
    # Bulk-deletes the user's read notifications. Returns the count removed so
    # the caller can flash a confirmation ("3 notificaciones eliminadas").
    class DestroyRead < SimpleUseCase
      def call(user:)
        user.notifications.read_only.delete_all
      end
    end
  end
end
