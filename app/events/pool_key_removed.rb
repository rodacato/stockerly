class PoolKeyRemoved < BaseEvent
  attribute :pool_key_id, Types::Integer
  attribute :key_name, Types::String
end
