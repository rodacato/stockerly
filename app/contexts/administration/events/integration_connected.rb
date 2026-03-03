module Administration
  module Events
    class IntegrationConnected < BaseEvent
      attribute :integration_id, Types::Integer
      attribute :provider_name, Types::String
    end
  end
end
