class AlertEvaluator
  def self.evaluate(rules, asset, new_price)
    rules.select do |rule|
      triggered?(rule, asset, new_price)
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
    else
      false
    end
  end

  private_class_method :triggered?
end
