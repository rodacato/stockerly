module Assistant
  module Events
    class ConnectionVerified < BaseEvent
      attribute :status, Types::String
    end
  end
end
