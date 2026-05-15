module MarketData
  module UseCases
    # Daily detector for technical-zone transitions (#40 JTBD #6). Iterates
    # assets with sufficient price history, compares today's indicators
    # against yesterday's, and persists a TechnicalObservation row for each
    # detected transition. Weekly dedup per (asset, type) prevents the
    # dashboard from flooding when an asset oscillates around a threshold.
    #
    # ADR-002: this use case does NOT filter by user state. Dashboard-side
    # presentation filters observations against watchlist + open positions.
    class DetectTechnicalObservations < ApplicationUseCase
      DEDUP_WINDOW_DAYS = 7

      def call
        detected = 0
        scannable_assets.find_each do |asset|
          detected += detect_for(asset)
        end
        Success(detected)
      end

      private

      def scannable_assets
        # `current_price` filter is a cheap "is this asset alive" proxy —
        # assets that never synced have nil and zero point in scanning.
        Asset.where.not(current_price: nil)
      end

      # Trailing window is SMA200's 201 closes + 1 to compare yesterday/today.
      # +8 buffer absorbs any future indicator that needs a slightly longer
      # lookback without forcing a redeploy. Anything older than this is dead
      # weight for the detector.
      WINDOW_SIZE = 210

      def detect_for(asset)
        # Bounded fetch: trailing window only, ordered oldest→newest after the
        # reverse. Avoids loading years of history per asset into memory.
        closes = asset.asset_price_histories
                      .order(date: :desc)
                      .limit(WINDOW_SIZE)
                      .pluck(:close)
                      .reverse
        return 0 if closes.size < 16 # RSI(14) needs 15 + we look back 1 day

        observed_at = Time.current
        events  = collect_rsi_transitions(closes)
        events += ma_crossings(closes, period: 50,  type_above: "ma50_crossed_above",  type_below: "ma50_crossed_below")
        events += ma_crossings(closes, period: 200, type_above: "ma200_crossed_above", type_below: "ma200_crossed_below")
        events += bollinger_breaches(closes)

        events.count { |e| persist_if_fresh(asset, e[:type], observed_at, e[:snapshot]) }
      end

      def collect_rsi_transitions(closes)
        rsi_now  = Domain::TechnicalIndicators.rsi(closes)
        rsi_prev = Domain::TechnicalIndicators.rsi(closes[0...-1])
        return [] if rsi_now.nil? || rsi_prev.nil?

        snap = { rsi: rsi_now, prev_rsi: rsi_prev, close: closes.last.to_f }
        events = []
        events << { type: "rsi_oversold_entered",   snapshot: snap } if rsi_prev >= 30 && rsi_now < 30
        events << { type: "rsi_oversold_exited",    snapshot: snap } if rsi_prev < 30 && rsi_now >= 30
        events << { type: "rsi_overbought_entered", snapshot: snap } if rsi_prev <= 70 && rsi_now > 70
        events << { type: "rsi_overbought_exited",  snapshot: snap } if rsi_prev > 70 && rsi_now <= 70
        events
      end

      def ma_crossings(closes, period:, type_above:, type_below:)
        return [] if closes.size < period + 1

        ma_now  = Domain::TechnicalIndicators.sma(closes, period: period)
        ma_prev = Domain::TechnicalIndicators.sma(closes[0...-1], period: period)
        return [] if ma_now.nil? || ma_prev.nil?

        close_now  = closes.last.to_f
        close_prev = closes[-2].to_f
        snap = { close: close_now, prev_close: close_prev, "ma#{period}" => ma_now, "prev_ma#{period}" => ma_prev }

        events = []
        events << { type: type_above, snapshot: snap } if close_prev <= ma_prev && close_now > ma_now
        events << { type: type_below, snapshot: snap } if close_prev >= ma_prev && close_now < ma_now
        events
      end

      def bollinger_breaches(closes)
        return [] if closes.size < 21

        bb_now  = Domain::TechnicalIndicators.bollinger_bands(closes)
        bb_prev = Domain::TechnicalIndicators.bollinger_bands(closes[0...-1])
        return [] if bb_now.nil? || bb_prev.nil?

        close_now  = closes.last.to_f
        close_prev = closes[-2].to_f

        events = []
        if close_prev <= bb_prev[:upper] && close_now > bb_now[:upper]
          events << { type: "bb_upper_breached", snapshot: { close: close_now, prev_close: close_prev, bb_upper: bb_now[:upper], bb_lower: bb_now[:lower] } }
        end
        if close_prev >= bb_prev[:lower] && close_now < bb_now[:lower]
          events << { type: "bb_lower_breached", snapshot: { close: close_now, prev_close: close_prev, bb_upper: bb_now[:upper], bb_lower: bb_now[:lower] } }
        end
        events
      end

      # Weekly cooldown per (asset, observation_type). Prevents flooding
      # when an asset oscillates around a threshold. Persistence failures
      # are logged but never crash the daily job — one bad asset must not
      # block the rest of the universe.
      def persist_if_fresh(asset, type, observed_at, snapshot)
        recent_exists = asset.technical_observations
                             .where(observation_type: type)
                             .where(observed_at: DEDUP_WINDOW_DAYS.days.ago..)
                             .exists?
        return false if recent_exists

        TechnicalObservation.create!(
          asset: asset,
          observation_type: type,
          observed_at: observed_at,
          indicator_snapshot: snapshot
        )
        true
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Rails.logger.warn(
          "[DetectTechnicalObservations] Skipped #{asset.symbol} / #{type}: #{e.message}"
        )
        false
      end
    end
  end
end
