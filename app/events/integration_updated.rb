class IntegrationUpdated < BaseEvent
  attribute :integration_id, Types::Integer
  attribute :provider_name, Types::String
  attribute :changes, Types::Hash
end
