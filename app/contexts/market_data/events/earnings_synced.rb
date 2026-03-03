module MarketData
  module Events
    class EarningsSynced < BaseEvent
      attribute :count, Types::Integer
    end
  end
end
