module Identity
  module Events
    class ProfileUpdated < BaseEvent
      attribute :user_id, Types::Integer
    end
  end
end
