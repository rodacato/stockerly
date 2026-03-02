module Trading
  module Handlers
    class LogTradeDelete
      def self.call(event)
        user_id  = event.is_a?(Hash) ? event[:user_id] : event.user_id
        trade_id = event.is_a?(Hash) ? event[:trade_id] : event.trade_id

        trade = Trade.find_by(id: trade_id)

        AuditLog.create!(
          user_id: user_id,
          action: "trade_deleted",
          auditable: trade,
          changes_data: "Trade ##{trade_id} soft-deleted"
        )
      end
    end
  end
end
