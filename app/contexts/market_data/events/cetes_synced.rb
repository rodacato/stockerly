module MarketData
  module Events
    class CetesSynced < BaseEvent
      attribute :count, Types::Integer
    end
  end
end
