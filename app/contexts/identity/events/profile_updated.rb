module Identity
  class ProfileUpdated < BaseEvent
    attribute :user_id, Types::Integer
  end
end
