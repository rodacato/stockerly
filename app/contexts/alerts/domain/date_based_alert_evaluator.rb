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
          when "dividend_ex_date" then evaluate_dividend_ex_date(rule, today)
          when "bmv_holiday"      then evaluate_bmv_holiday(rule, today)
          when "cete_auction"     then evaluate_cete_auction(rule, today)
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

      # Fires on the boundary day: when a BMV holiday is exactly `window_days`
      # ahead. Same boundary-trigger semantics as dividend_ex_date — prevents
      # daily spam while the holiday stays in range.
      def self.evaluate_bmv_holiday(rule, today)
        window = (rule.window_days || DEFAULT_WINDOW_DAYS).to_i
        target_date = today + window.days
        holiday = MarketHoliday.find_by(market: :BMV, date: target_date)
        return nil unless holiday

        Result.new(rule: rule, event_date: holiday.date, context: {
          days_until: window,
          holiday_name: holiday.name
        })
      end

      # Fires when the next Banxico-business-day auction (every Tuesday, skipped
      # on Banxico holidays) is exactly `window_days` ahead. Schedule is derived
      # — Stockerly doesn't sync Banxico's published auction calendar, but
      # auctions land deterministically on Tuesdays.
      def self.evaluate_cete_auction(rule, today)
        window = (rule.window_days || DEFAULT_WINDOW_DAYS).to_i
        target_date = today + window.days
        return nil unless next_cete_auction_date(from: target_date) == target_date

        Result.new(rule: rule, event_date: target_date, context: {
          days_until: window
        })
      end

      # First Banxico-business-Tuesday on/after `from`. Walks day-by-day
      # accepting Tuesdays that aren't on the Banxico holiday list. If
      # `from` is itself a non-Tuesday weekday, the result is the next
      # Tuesday; if `from` is a Tuesday holiday, the result is the Tuesday
      # of the following week.
      def self.next_cete_auction_date(from:)
        candidate = from
        loop do
          return candidate if candidate.tuesday? && !MarketHoliday.holiday?(market: :Banxico, date: candidate)
          candidate += 1
        end
      end

      private_class_method :evaluate_dividend_ex_date, :evaluate_bmv_holiday, :evaluate_cete_auction
    end
  end
end
