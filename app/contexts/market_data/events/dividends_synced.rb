module MarketData
  module Events
    class DividendsSynced < BaseEvent
      attribute :asset_count, Types::Integer
      attribute :dividend_count, Types::Integer
    end
  end
end
