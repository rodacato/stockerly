module Alerts
  module Domain
    # Evaluates alert rules whose trigger condition depends on a calendar date
    # (not on a price update). Runs from Alerts::EvaluateDateBasedAlertsJob
    # once a day. Returns the list of rules that should fire today plus the
    # event payload to broadcast.
    class DateBasedAlertEvaluator
      Result = Struct.new(:rule, :event_date, :context, keyword_init: true)

      def self.evaluate(rules, today: Date.current)
        rules.filter_map do |rule|
          next unless rule.cooled_down?

          case rule.condition
          when "dividend_ex_date"
            evaluate_dividend_ex_date(rule, today)
          end
        end
      end

      def self.evaluate_dividend_ex_date(rule, today)
        asset = Asset.find_by("LOWER(symbol) = ?", rule.asset_symbol.downcase)
        return nil unless asset

        window = (rule.window_days || 7).to_i
        dividend = asset.dividends
                        .where(ex_date: today..(today + window.days))
                        .order(:ex_date)
                        .first
        return nil unless dividend

        Result.new(rule: rule, event_date: dividend.ex_date, context: {
          days_until: (dividend.ex_date - today).to_i,
          amount_per_share: dividend.amount_per_share,
          currency: dividend.currency
        })
      end

      private_class_method :evaluate_dividend_ex_date
    end
  end
end
