module Identity
  module Events
    class UserRegistered < BaseEvent
      attribute :user_id, Types::Integer
      attribute :email, Types::String
    end
  end
end
