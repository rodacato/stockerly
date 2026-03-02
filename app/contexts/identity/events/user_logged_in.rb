module Identity
  module Events
    class UserLoggedIn < BaseEvent
      attribute :user_id, Types::Integer
      attribute :ip_address, Types::String
      attribute :user_agent, Types::String
    end
  end
end
