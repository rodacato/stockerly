module Notifications
  module UseCases
    # ADR-006: pure read, no failure path → SimpleUseCase.
    # Returns a hash because the controller needs both the relation and
    # the unread count — splitting into two use cases would duplicate
    # the user.notifications scope traversal.
    class ListRecent < SimpleUseCase
      def call(user:)
        {
          notifications: user.notifications.recent,
          unread_count: user.notifications.unread.count
        }
      end
    end
  end
end
