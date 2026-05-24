module Trading
  module Handlers
    # Records a UserActivity row when a trade is executed. Pulls the asset
    # symbol from the persisted Trade since the event only carries the
    # trade_id + side + shares.
    class RecordTradeActivity
      def self.call(event)
        user_id  = event.is_a?(Hash) ? event[:user_id] : event.user_id
        trade_id = event.is_a?(Hash) ? event[:trade_id] : event.trade_id
        side     = event.is_a?(Hash) ? event[:side] : event.side
        shares   = event.is_a?(Hash) ? event[:shares] : event.shares

        trade = Trade.find_by(id: trade_id)
        return unless trade

        ActivityRecorder.call(
          user:   User.find_by(id: user_id),
          action: "trade_executed",
          params: {
            asset_symbol: trade.asset&.symbol,
            side:         side.to_s,
            shares:       shares.to_s
          }
        )
      end
    end
  end
end
