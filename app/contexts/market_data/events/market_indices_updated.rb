module MarketData
  module Events
    class MarketIndicesUpdated < BaseEvent
      attribute :count, Types::Integer
    end
  end
end
