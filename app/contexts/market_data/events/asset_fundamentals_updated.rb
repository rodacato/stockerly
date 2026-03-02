module MarketData
  class AssetFundamentalsUpdated < BaseEvent
    attribute :asset_id, Types::Integer
    attribute :symbol, Types::String
    attribute :source, Types::String
  end
end
