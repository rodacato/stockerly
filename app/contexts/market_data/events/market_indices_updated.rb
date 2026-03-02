module MarketData
  class MarketIndicesUpdated < BaseEvent
    attribute :count, Types::Integer
  end
end
