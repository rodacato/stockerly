module Alerts
  module Domain
    class AlertEvaluator
      def self.evaluate(rules, asset, new_price)
        rules.select do |rule|
          next false if rule.daily_once? && rule.fired_today?

          rule.cooled_down? && triggered?(rule, asset, new_price)
        end
      end

      def self.triggered?(rule, asset, new_price)
        old_price = asset.current_price || 0

        case rule.condition
        when "price_crosses_above"
          old_price < rule.threshold_value && new_price >= rule.threshold_value
        when "price_crosses_below"
          old_price > rule.threshold_value && new_price <= rule.threshold_value
        when "day_change_percent"
          change = day_change(asset, new_price)
          return false if change.nil?
          change.abs >= rule.threshold_value
        when "rsi_overbought"
          score = asset.latest_trend_score&.score || 0
          score >= rule.threshold_value
        when "rsi_oversold"
          score = asset.latest_trend_score&.score || 0
          score <= rule.threshold_value
        when "volume_spike"
          avg = average_volume(asset)
          return false if avg.zero?
          (asset.volume || 0) >= rule.threshold_value * avg
        else
          false
        end
      end

      # The day change as every screen defines it (ADR-021), measured against
      # the price that is arriving rather than the row on disk: this handler is
      # subscribed ahead of RecordPriceHistory, so today's row still carries the
      # previous sync's price when a rule is evaluated.
      #
      # nil when there is no earlier close — a newly tracked asset has no day
      # change, and unknown must not read as no movement.
      def self.day_change(asset, new_price)
        previous = MarketData::Queries::PriceSeries.for(asset).latest(2)
                     .reject { |row| row.date >= Date.current }
                     .last
        return nil if previous.nil?

        MarketData::Domain::DayChange.from_closes([ previous.close, new_price ])
      end

      def self.average_volume(asset, days: 5)
        MarketData::Queries::PriceSeries.for(asset).average_volume(days)
      end

      private_class_method :triggered?, :average_volume, :day_change
    end
  end
end
