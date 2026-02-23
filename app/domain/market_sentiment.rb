class MarketSentiment
  LABELS = {
    (0..20) => "Very Bearish",
    (21..40) => "Bearish",
    (41..60) => "Neutral",
    (61..80) => "Bullish",
    (81..100) => "Very Bullish"
  }.freeze

  def self.for_user(user)
    scores = watchlist_scores(user)
    return { value: 50, label: "Neutral" } if scores.empty?

    avg = scores.sum / scores.size.to_f
    value = avg.round
    { value: value, label: label_for(value) }
  end

  def self.global
    scores = TrendScore.latest.limit(50).pluck(:score)
    return { value: 50, label: "Neutral" } if scores.empty?

    avg = scores.sum / scores.size.to_f
    value = avg.round
    { value: value, label: label_for(value) }
  end

  def self.label_for(value)
    LABELS.find { |range, _| range.include?(value) }&.last || "Neutral"
  end

  def self.watchlist_scores(user)
    asset_ids = user.watchlist_items.pluck(:asset_id)
    return [] if asset_ids.empty?

    TrendScore
      .where(asset_id: asset_ids)
      .where(
        "(asset_id, calculated_at) IN (SELECT asset_id, MAX(calculated_at) FROM trend_scores WHERE asset_id IN (?) GROUP BY asset_id)",
        asset_ids
      )
      .pluck(:score)
  end

  private_class_method :watchlist_scores, :label_for
end
