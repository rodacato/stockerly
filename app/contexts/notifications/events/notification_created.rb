module Notifications
  module Events
    class NotificationCreated < BaseEvent
      attribute :notification_id, Types::Integer
      attribute :user_id, Types::Integer
      attribute :title, Types::String
    end
  end
end
