module Identity
  class PasswordChanged < BaseEvent
    attribute :user_id, Types::Integer
  end
end
