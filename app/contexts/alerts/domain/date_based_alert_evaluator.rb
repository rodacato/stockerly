module Alerts
  module Domain
    # Evaluates alert rules whose trigger condition depends on a calendar date
    # (not on a price update). Runs from Alerts::EvaluateDateBasedAlertsJob
    # once a day. Returns the list of rules that should fire today plus the
    # event payload to broadcast.
    class DateBasedAlertEvaluator
      Result = Struct.new(:rule, :event_date, :context, keyword_init: true)

      DEFAULT_WINDOW_DAYS = 7

      def self.evaluate(rules, today: Date.current)
        rules.filter_map do |rule|
          next unless rule.cooled_down?

          case rule.condition
          when "dividend_ex_date"
            evaluate_dividend_ex_date(rule, today)
          end
        end
      end

      # Fires exactly once per dividend: on the day the ex-date is `window_days`
      # away (the moment the dividend enters the user's notice window). Using
      # `today + window_days` instead of a range avoids spamming the user every
      # day the dividend stays in range — `AlertRule#cooldown_minutes` alone
      # can't prevent that because its default is 60 minutes.
      def self.evaluate_dividend_ex_date(rule, today)
        asset = Asset.find_by(symbol: rule.asset_symbol.upcase)
        return nil unless asset

        window = (rule.window_days || DEFAULT_WINDOW_DAYS).to_i
        target_date = today + window.days
        dividend = asset.dividends.where(ex_date: target_date).order(:ex_date).first
        return nil unless dividend

        Result.new(rule: rule, event_date: dividend.ex_date, context: {
          days_until: window,
          amount_per_share: dividend.amount_per_share,
          currency: dividend.currency
        })
      end

      private_class_method :evaluate_dividend_ex_date
    end
  end
end
