module Identity
  class EmailVerified < BaseEvent
    attribute :user_id, Types::Integer
    attribute :email, Types::String
  end
end
