module MarketData
  class FearGreedUpdated < BaseEvent
    attribute :index_type, Types::String
    attribute :value, Types::Integer
    attribute :classification, Types::String
  end
end
