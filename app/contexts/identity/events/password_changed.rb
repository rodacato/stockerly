module Identity
  module Events
    class PasswordChanged < BaseEvent
      attribute :user_id, Types::Integer
    end
  end
end
