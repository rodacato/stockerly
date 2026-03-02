module Alerts
  module Domain
    class AlertEvaluator
      def self.evaluate(rules, asset, new_price)
        rules.select do |rule|
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
          return false if old_price.zero?
          change_pct = ((new_price - old_price) / old_price * 100).abs
          change_pct >= rule.threshold_value
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

      def self.evaluate_sentiment(rules, fg_value)
        rules.select { |rule| sentiment_triggered?(rule, fg_value) }
      end

      def self.sentiment_triggered?(rule, fg_value)
        case rule.condition
        when "sentiment_above"
          fg_value >= rule.threshold_value
        when "sentiment_below"
          fg_value <= rule.threshold_value
        else
          false
        end
      end

      def self.average_volume(asset, days: 5)
        asset.asset_price_histories.where("date >= ?", days.days.ago.to_date).average(:volume)&.to_i || 0
      end

      private_class_method :triggered?, :sentiment_triggered?, :average_volume
    end
  end
end
