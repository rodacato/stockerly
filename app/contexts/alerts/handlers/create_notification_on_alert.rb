module Alerts
  module Handlers
    class CreateNotificationOnAlert
      def self.async? = true

      def self.call(event)
        user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
        symbol  = event.is_a?(Hash) ? event[:asset_symbol] : event.asset_symbol
        price   = event.is_a?(Hash) ? event[:triggered_price] : event.triggered_price
        rule_id = event.is_a?(Hash) ? event[:alert_rule_id] : event.alert_rule_id

        rule = AlertRule.find_by(id: rule_id)

        Notifications::UseCases::CreateNotification.new.call(
          user_id: user_id,
          title: "Alerta disparada: #{symbol}",
          body:  "Tu alerta para #{symbol} se disparó. Precio: #{price}.",
          notification_type: :alert_triggered,
          notifiable: rule
        )
      end
    end
  end
end
