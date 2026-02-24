class RecalculateTrendScoreOnPriceUpdate
  def self.async? = true

  def self.call(event)
    asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id

    asset = Asset.find_by(id: asset_id)
    return unless asset

    closes = asset.asset_price_histories.recent(30).pluck(:close).map(&:to_f)
    result = TrendScoreCalculator.calculate(closes: closes)
    return unless result

    asset.trend_scores.create!(
      score: result[:score],
      label: result[:label],
      direction: result[:direction],
      calculated_at: Time.current
    )
  end
end
