class PoolKeyToggled < BaseEvent
  attribute :pool_key_id, Types::Integer
  attribute :key_name, Types::String
  attribute :enabled, Types::Bool
end
