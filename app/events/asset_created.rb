class AssetCreated < BaseEvent
  attribute :asset_id, Types::Integer
  attribute :symbol, Types::String
  attribute :admin_id, Types::Integer
end
