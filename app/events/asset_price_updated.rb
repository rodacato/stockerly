class AssetPriceUpdated < BaseEvent
  attribute :asset_id, Types::Integer
  attribute :symbol, Types::String
  attribute :old_price, Types::String
  attribute :new_price, Types::String
end
