module Administration
  class IntegrationConnected < BaseEvent
    attribute :integration_id, Types::Integer
    attribute :provider_name, Types::String
  end
end
