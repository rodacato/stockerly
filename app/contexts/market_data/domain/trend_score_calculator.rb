module MarketData
  module Domain
    # Pure stateless calculator for trend scores.
    # Receives array of closing prices (oldest→newest, min 15 elements), returns score hash.
    # No DB reads, no I/O, no side effects.
    #
    # Graceful degradation:
    # - ≥35 closes (+ volumes) → 5-factor: RSI 30%, Momentum 20%, MACD 20%, Volume 15%, EMA 15%
    # - 15-34 closes → 2-factor fallback: RSI 60%, Momentum 40% (backward compatible)
    class TrendScoreCalculator
    class << self
    def calculate(closes:, volumes: nil)
      return nil if closes.blank? || closes.size < 15

      rsi = rsi_14(closes)
      momentum = momentum_7d(closes)
      return nil unless rsi && momentum

      if closes.size >= 35
        macd = macd_signal(closes)
        vol = volumes.present? ? volume_trend(volumes, momentum) : nil
        ema = ema_crossover(closes)

        score = blend_5_factor(rsi, momentum, macd, vol, ema)
        factors = {
          rsi: rsi.round(1),
          momentum: normalize_momentum(momentum).round(1),
          macd: macd&.round(1),
          volume_trend: vol&.round(1),
          ema_crossover: ema&.round(1)
        }
      else
        score = blend(rsi, momentum)
        factors = { rsi: rsi.round(1), momentum: normalize_momentum(momentum).round(1) }
      end

      { score: score, label: label_for(score), direction: momentum >= 0 ? :upward : :downward, factors: factors }
    end

    private

    def rsi_14(closes)
      return nil if closes.size < 15

      deltas = closes.last(15).each_cons(2).map { |a, b| b - a }
      gains = deltas.map { |d| d.positive? ? d : 0.0 }
      losses = deltas.map { |d| d.negative? ? d.abs : 0.0 }

      avg_gain = gains.sum / 14.0
      avg_loss = losses.sum / 14.0
      return 50.0 if avg_gain.zero? && avg_loss.zero?
      return 100.0 if avg_loss.zero?

      rs = avg_gain / avg_loss
      (100.0 - (100.0 / (1.0 + rs))).round(2)
    end

    def momentum_7d(closes)
      return nil if closes.size < 8
      old = closes[-8].to_f
      return nil if old.zero?
      ((closes.last.to_f - old) / old * 100.0).round(2)
    end

    def normalize_momentum(momentum)
      ((momentum.clamp(-20, 20) + 20) * 2.5)
    end

    def compute_ema_series(values, period)
      return [] if values.size < period

      multiplier = 2.0 / (period + 1)
      ema = values.first(period).sum / period.to_f
      series = [ ema ]

      values[period..].each do |val|
        ema = (val - ema) * multiplier + ema
        series << ema
      end

      series
    end

    def macd_signal(closes)
      ema12 = compute_ema_series(closes, 12)
      ema26 = compute_ema_series(closes, 26)
      return nil if ema12.empty? || ema26.empty?

      # Align: ema12 starts at index 12, ema26 at index 26
      # MACD line length = ema12.size - (26 - 12) = ema12.size - 14
      offset = 26 - 12
      return nil if ema12.size <= offset

      macd_line = ema12[offset..].zip(ema26).map { |e12, e26| e12 - e26 }
      signal_line = compute_ema_series(macd_line, 9)
      return nil if signal_line.empty?

      histogram = macd_line.last - signal_line.last
      # Normalize histogram to 0-100: positive histogram → >50, negative → <50
      # Typical histogram range ~±2% of price, so normalize by last close
      last_price = closes.last.to_f
      return 50.0 if last_price.zero?

      normalized = (histogram / last_price) * 1000.0
      (normalized.clamp(-50, 50) + 50).clamp(0, 100)
    end

    def volume_trend(volumes, momentum)
      return nil if volumes.blank? || volumes.size < 20

      avg_5d = volumes.last(5).sum / 5.0
      avg_20d = volumes.last(20).sum / 20.0
      return 50.0 if avg_20d.zero?

      ratio = avg_5d / avg_20d
      # Invert ratio when bearish: high volume in downtrend = bearish signal
      ratio = 1.0 / ratio if momentum < 0 && ratio > 0
      # Normalize ratio (0.5-2.0) to 0-100
      ((ratio - 0.5) / 1.5 * 100.0).clamp(0, 100)
    end

    def ema_crossover(closes)
      ema9 = compute_ema_series(closes, 9)
      ema21 = compute_ema_series(closes, 21)
      return nil if ema9.empty? || ema21.empty?

      # Align to the shorter series
      offset = 21 - 9
      return nil if ema9.size <= offset

      short_val = ema9.last
      long_val = ema21.last
      last_price = closes.last.to_f
      return 50.0 if last_price.zero?

      spread = (short_val - long_val) / last_price * 100.0
      # Normalize spread (-5% to +5%) to 0-100
      (spread.clamp(-5, 5) * 10.0 + 50.0).clamp(0, 100)
    end

    def blend_5_factor(rsi, momentum, macd, vol, ema)
      norm_rsi = rsi.clamp(0, 100)
      norm_momentum = normalize_momentum(momentum)

      total_weight = 0.3 + 0.2 # RSI + momentum always present
      weighted = 0.3 * norm_rsi + 0.2 * norm_momentum

      if macd
        weighted += 0.2 * macd
        total_weight += 0.2
      end
      if vol
        weighted += 0.15 * vol
        total_weight += 0.15
      end
      if ema
        weighted += 0.15 * ema
        total_weight += 0.15
      end

      (weighted / total_weight * 1.0).clamp(0, 100).round
    end

    def blend(rsi, momentum)
      norm_rsi = rsi.clamp(0, 100)
      norm_momentum = normalize_momentum(momentum)
      (0.6 * norm_rsi + 0.4 * norm_momentum).clamp(0, 100).round
    end

    def label_for(score)
      case score
      when 0..20   then :weak
      when 21..40  then :weakening
      when 41..60  then :sideways
      when 61..80  then :moderate
      when 81..90  then :strong
      when 91..100 then :parabolic
      end
    end
    end
    end
  end
end
