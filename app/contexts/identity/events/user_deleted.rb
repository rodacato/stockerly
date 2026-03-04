module Identity
  module Events
    class UserDeleted < BaseEvent
      attribute :user_id,   Types::Integer
      attribute :email,     Types::String
      attribute :full_name, Types::String
      attribute :admin_id,  Types::Integer
    end
  end
end
