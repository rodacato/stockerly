module MarketData
  module Events
    class NewsSynced < BaseEvent
      attribute :count, Types::Integer
    end
  end
end
