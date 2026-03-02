module Identity
  class UserRegistered < BaseEvent
    attribute :user_id, Types::Integer
    attribute :email, Types::String
  end
end
