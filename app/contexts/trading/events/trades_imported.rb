module Trading
  module Events
    # One event per batch, never one per row. An import is a replay, not N
    # executions — publishing TradeExecuted per trade is what makes the
    # backdated-snapshot handler rebuild the same range N times.
    class TradesImported < BaseEvent
      attribute :portfolio_id, Types::Integer
      attribute :user_id, Types::Integer
      attribute :trade_count, Types::Integer
      attribute :earliest_executed_on, Types::String
    end
  end
end
