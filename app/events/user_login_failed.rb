class UserLoginFailed < BaseEvent
  attribute :email, Types::String
  attribute :ip_address, Types::String
  attribute :user_agent, Types::String
end
