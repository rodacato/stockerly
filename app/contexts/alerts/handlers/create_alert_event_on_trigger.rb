module Alerts
  module Handlers
    class CreateAlertEventOnTrigger
      def self.call(event)
        rule_id   = event.is_a?(Hash) ? event[:alert_rule_id] : event.alert_rule_id
        user_id   = event.is_a?(Hash) ? event[:user_id] : event.user_id
        symbol    = event.is_a?(Hash) ? event[:asset_symbol] : event.asset_symbol
        price     = event.is_a?(Hash) ? event[:triggered_price] : event.triggered_price
        context   = event.is_a?(Hash) ? event[:context] : (event.respond_to?(:context) ? event.context : {})

        rule = AlertRule.find_by(id: rule_id)
        # Marketwide alerts (bmv_holiday / cete_auction) don't bind to an asset
        # symbol — surface the rule's display name instead so AlertEvent still
        # has something to render in the live feed. Use `.presence` because the
        # publisher passes `asset_symbol.to_s` (truthy `""` for marketwide
        # rules), so `||=` would never fire and AlertEvent.asset_symbol would
        # land as an empty string.
        symbol = symbol.presence || (rule&.condition == "bmv_holiday" ? "BMV" : "CETES")

        AlertEvent.create!(
          alert_rule: rule,
          user_id: user_id,
          asset_symbol: symbol,
          message: build_message(rule, symbol, price, context),
          triggered_at: Time.current,
          event_status: :triggered
        )

        rule&.update!(last_triggered_at: Time.current)
      end

      # Descriptive (not prescriptive) per ADR-0001 — the message reports what
      # happened in es-MX; never tells the user what to do.
      def self.build_message(rule, symbol, value, context = nil)
        return "#{symbol}: alerta disparada" unless rule

        ctx = (context || {}).to_h

        case rule.condition
        when "price_crosses_above"
          "#{symbol} cruzó #{format_threshold(rule)} al alza (precio: #{value})."
        when "price_crosses_below"
          "#{symbol} cruzó #{format_threshold(rule)} a la baja (precio: #{value})."
        when "day_change_percent"
          "#{symbol} se movió más de #{rule.threshold_value.to_f.round(2)}% en el día (precio: #{value})."
        when "rsi_overbought"
          "#{symbol} aparece sobrecomprado (RSI ≥ #{rule.threshold_value.to_i})."
        when "rsi_oversold"
          "#{symbol} aparece sobrevendido (RSI ≤ #{rule.threshold_value.to_i})."
        when "volume_spike"
          "#{symbol} registró volumen anómalo (más de #{rule.threshold_value.to_f.round(1)}× el promedio)."
        when "dividend_ex_date"
          "#{symbol}: ex-date de dividendo el #{value}."
        when "bmv_holiday"
          days = ctx[:days_until] || rule.window_days
          name = ctx[:holiday_name] || "festivo BMV"
          "BMV cerrado en #{days} día(s): #{name}."
        when "cete_auction"
          days = ctx[:days_until] || rule.window_days
          "Próxima subasta Banxico de CETES en #{days} día(s)."
        else
          "#{symbol}: alerta disparada."
        end
      end

      def self.format_threshold(rule)
        "#{rule.currency} #{format('%.2f', rule.threshold_value.to_f)}"
      end

      private_class_method :build_message, :format_threshold
    end
  end
end
