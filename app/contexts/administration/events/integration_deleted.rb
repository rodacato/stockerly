module Administration
  class IntegrationDeleted < BaseEvent
    attribute :integration_id, Types::Integer
    attribute :provider_name, Types::String
  end
end
