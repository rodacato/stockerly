module Trading
  class LogTradeActivity
    def self.call(event)
      user_id  = event.is_a?(Hash) ? event[:user_id] : event.user_id
      trade_id = event.is_a?(Hash) ? event[:trade_id] : event.trade_id
      side     = event.is_a?(Hash) ? event[:side] : event.side
      shares   = event.is_a?(Hash) ? event[:shares] : event.shares

      trade = Trade.find_by(id: trade_id)

      AuditLog.create!(
        user_id: user_id,
        action: "trade_#{side}",
        auditable: trade,
        changes_data: "#{side.upcase} #{shares} shares"
      )
    end
  end
end
