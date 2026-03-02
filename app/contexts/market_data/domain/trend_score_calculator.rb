module MarketData
  # Pure stateless calculator for trend scores.
  # Receives array of closing prices (oldest→newest, min 15 elements), returns score hash.
  # No DB reads, no I/O, no side effects.
  class TrendScoreCalculator
    class << self
    # Main entry point: array of closing prices → { score:, label:, direction: }
    # Returns nil if insufficient data (< 15 closes).
    def calculate(closes:)
      return nil if closes.blank? || closes.size < 15

      rsi = rsi_14(closes)
      momentum = momentum_7d(closes)
      return nil unless rsi && momentum

      score = blend(rsi, momentum)
      { score: score, label: label_for(score), direction: momentum >= 0 ? :upward : :downward }
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

    def blend(rsi, momentum)
      norm_rsi = rsi.clamp(0, 100)
      norm_momentum = ((momentum.clamp(-20, 20) + 20) * 2.5)
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
