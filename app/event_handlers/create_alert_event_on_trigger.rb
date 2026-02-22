class CreateAlertEventOnTrigger
  def self.call(event)
    rule_id   = event.is_a?(Hash) ? event[:alert_rule_id] : event.alert_rule_id
    user_id   = event.is_a?(Hash) ? event[:user_id] : event.user_id
    symbol    = event.is_a?(Hash) ? event[:asset_symbol] : event.asset_symbol
    price     = event.is_a?(Hash) ? event[:triggered_price] : event.triggered_price

    rule = AlertRule.find_by(id: rule_id)

    AlertEvent.create!(
      alert_rule: rule,
      user_id: user_id,
      asset_symbol: symbol,
      message: "#{symbol} alert triggered at $#{price}",
      triggered_at: Time.current,
      event_status: :triggered
    )
  end
end
