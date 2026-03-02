module Trading
  class LogTradeUpdate
    def self.call(event)
      user_id  = event.is_a?(Hash) ? event[:user_id] : event.user_id
      trade_id = event.is_a?(Hash) ? event[:trade_id] : event.trade_id
      changes  = event.is_a?(Hash) ? event[:changes] : event.changes

      trade = Trade.find_by(id: trade_id)

      AuditLog.create!(
        user_id: user_id,
        action: "trade_updated",
        auditable: trade,
        changes_data: changes.to_json
      )
    end
  end
end
