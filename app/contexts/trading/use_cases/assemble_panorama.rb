module Trading
  module UseCases
    # The Panorama (slice 3) — the daily cockpit that replaces /dashboard.
    # Four blocks: the patrimonio strip, the sentiment carousel, the
    # movements that carry a verb (ADR-013), and the radar.
    class AssemblePanorama < SimpleUseCase
      RADAR_LIMIT = 6
      MOVEMENTS_LIMIT = 3
      MATURITY_WINDOW_DAYS = 30

      SentimentCard = Data.define(:key, :value, :label_key, :delta)
      RadarEntry = Data.define(:kind, :record, :asset, :change, :maturity_days)

      def call(user:)
        portfolio = user.portfolio
        currency  = user.preferred_currency
        summary   = consolidated_summary(portfolio, currency)
        positions = open_positions(portfolio)
        watched   = user.watchlist_items.includes(:asset).to_a

        {
          currency: currency,
          summary: summary,
          fx_unavailable: portfolio.present? && summary.nil?,
          sentiment_cards: sentiment_cards(user),
          movements: movements(positions, watched),
          radar: radar(positions, watched)
        }
      end

      private

      # Valuing here is the load-bearing part: AssembleDashboard built the
      # summary lazily, so Portfolio#convert raised in the template instead.
      def consolidated_summary(portfolio, currency)
        return nil unless portfolio

        summary = Trading::Domain::PortfolioSummary.new(portfolio, currency: currency)
        summary.total_value
        summary.day_gain
        summary
      rescue RuntimeError
        nil
      end

      def open_positions(portfolio)
        return [] unless portfolio

        portfolio.open_positions.includes(:asset).to_a
      end

      def sentiment_cards(user)
        fear_greed = MarketData::Queries::CurrentFearGreed.call

        [
          fear_greed_card(:crypto, fear_greed[:crypto], fear_greed[:crypto_history]),
          fear_greed_card(:stocks, fear_greed[:stocks], fear_greed[:stocks_history]),
          watchlist_card(user)
        ].compact
      end

      def fear_greed_card(key, reading, history)
        return nil unless reading

        SentimentCard.new(
          key: key,
          value: reading.value,
          label_key: normalize(reading.classification),
          delta: previous_value(history)&.then { |prev| reading.value - prev }
        )
      end

      # The last reading from a different day than the current one. Anchoring on
      # the reading's own date rather than on Date.current matters after
      # midnight, when the freshest reading is already "yesterday" and the naive
      # filter compares it against itself.
      def previous_value(history)
        rows = history.to_a
        return nil if rows.empty?

        current_day = rows.last.first.to_date
        rows.reject { |fetched_at, _| fetched_at.to_date == current_day }.last&.last
      end

      def watchlist_card(user)
        return nil if user.watchlist_items.empty?

        sentiment = MarketData::Domain::MarketSentiment.for_user(user)
        SentimentCard.new(
          key: :watchlist,
          value: sentiment[:value],
          label_key: normalize(sentiment[:label]),
          delta: MarketData::Domain::MarketSentiment.delta_for_user(user)
        )
      end

      def normalize(label) = label.to_s.parameterize(separator: "_")

      def movements(positions, watched)
        MarketData::Queries::NotableObservations.call(
          asset_ids: asset_ids_of(positions, watched),
          limit: MOVEMENTS_LIMIT
        )
      end

      def asset_ids_of(positions, watched)
        (positions.map(&:asset_id) + watched.map(&:asset_id)).uniq
      end

      # "Con actividad hoy" is taken literally: the asset moved, or a fixed
      # income position matures soon enough that its silence is the news.
      def radar(positions, watched)
        entries = positions.map { |p| entry_for(:position, p, maturity_days_of(p)) } +
                  watched.map { |w| entry_for(:watchlist, w, nil) }

        entries
          .select { |e| e.change.abs.positive? || e.maturity_days }
          .sort_by { |e| [ e.maturity_days ? 0 : 1, -e.change.abs ] }
          .first(RADAR_LIMIT)
      end

      def entry_for(kind, record, maturity_days)
        asset = record.asset
        RadarEntry.new(
          kind: kind,
          record: record,
          asset: asset,
          change: asset.change_percent_24h.to_f,
          maturity_days: maturity_days
        )
      end

      def maturity_days_of(position)
        date = position.maturity_date
        return nil if date.blank?

        days = (date - Date.current).to_i
        days if days.between?(0, MATURITY_WINDOW_DAYS)
      end
    end
  end
end
