module Identity
  module Events
    class UserReactivated < BaseEvent
      attribute :user_id,  Types::Integer
      attribute :email,    Types::String
      attribute :admin_id, Types::Integer
    end
  end
end
