module MarketData
  class AllGatewaysFailed < BaseEvent
    attribute :asset_id, Types::Integer
    attribute :symbol, Types::String
    attribute :attempted_gateways, Types::Array.of(Types::String)
  end
end
