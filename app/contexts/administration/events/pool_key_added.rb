module Administration
  module Events
    class PoolKeyAdded < BaseEvent
      attribute :integration_id, Types::Integer
      attribute :pool_key_id, Types::Integer
      attribute :key_name, Types::String
    end
  end
end
