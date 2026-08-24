module MarketData
  module Domain
    class MarketSentiment
    LABELS = {
      (0..20) => "Very Bearish",
      (21..40) => "Bearish",
      (41..60) => "Neutral",
      (61..80) => "Bullish",
      (81..100) => "Very Bullish"
    }.freeze

    # Cross-context read API — Trading may call this (ADR-002, grandfathered).
    # Returns the user's watchlist sentiment as { value: 0..100, label: String }.
    # @api public
    def self.for_user(user)
      scores = watchlist_scores(user)
      return { value: 50, label: "Neutral" } if scores.empty?

      value = average(scores)
      { value: value, label: label_for(value) }
    end

    # The move since the previous daily calculation, or nil when there is no
    # earlier reading to compare against. CalculateTrendScoresJob runs once a
    # day, so "previous" means yesterday.
    # @api public
    def self.delta_for_user(user)
      current = watchlist_scores(user)
      return nil if current.empty?

      earlier = watchlist_scores(user, before: Date.current.beginning_of_day)
      return nil if earlier.empty?

      average(current) - average(earlier)
    end

    def self.global
      scores = TrendScore.latest.limit(50).pluck(:score)
      return { value: 50, label: "Neutral" } if scores.empty?

      value = average(scores)
      { value: value, label: label_for(value) }
    end

    def self.label_for(value)
      LABELS.find { |range, _| range.include?(value) }&.last || "Neutral"
    end

    def self.average(scores)
      (scores.sum / scores.size.to_f).round
    end

    # The tuple match is load-bearing: the job calculates a batch in one pass,
    # so several assets share a calculated_at and matching on the timestamp
    # alone would pull in another asset's score.
    def self.watchlist_scores(user, before: nil)
      asset_ids = user.watchlist_items.pluck(:asset_id)
      return [] if asset_ids.empty?

      latest = TrendScore.where(asset_id: asset_ids)
      latest = latest.where(calculated_at: ...before) if before
      latest = latest.group(:asset_id).select("asset_id, MAX(calculated_at)")

      TrendScore
        .where(asset_id: asset_ids)
        .where("(asset_id, calculated_at) IN (#{latest.to_sql})")
        .pluck(:score)
    end

    private_class_method :watchlist_scores, :label_for, :average
    end
  end
end
