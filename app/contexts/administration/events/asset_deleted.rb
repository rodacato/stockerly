module MarketData
  module Events
    class AssetDeleted < BaseEvent
      attribute :asset_symbol, Types::String
      attribute :admin_id, Types::Integer
    end
  end
end
