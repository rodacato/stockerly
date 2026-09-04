module MarketData
  module Domain
    # Pure stateless calculator for trend scores.
    # Receives array of closing prices (oldest→newest, min 15 elements), returns score hash.
    # No DB reads, no I/O, no side effects.
    #
    # Every factor is attempted and each one gates on its own minimum, so a short
    # series yields the factors it can support rather than none. `factors` carries
    # only what was computable; FACTORS minus its keys is what the reading is missing.
    class TrendScoreCalculator
      FACTORS = %i[rsi momentum macd volume_trend ema_crossover].freeze

      # Rows to hand this calculator, expressed in rows because its own minimums
      # are: MACD needs 34 closes and a 50-calendar-day window is ~35 trading
      # rows for a stock, two market holidays short of it.
      WINDOW = 60

    class << self
    def calculate(closes:, volumes: nil)
      return nil if closes.blank? || closes.size < 15

      rsi = rsi_14(closes)
      momentum = momentum_7d(closes)
      return nil unless rsi && momentum

      macd = macd_signal(closes)
      vol = volumes.present? ? volume_trend(volumes, momentum) : nil
      ema = ema_crossover(closes)

      score = blend_5_factor(rsi, momentum, macd, vol, ema)
      factors = {
        rsi: rsi,
        momentum: normalize_momentum(momentum),
        macd: macd,
        volume_trend: vol,
        ema_crossover: ema
      }.compact.transform_values { |factor| factor.round(1) }

      { score: score, label: label_for(score), direction: momentum >= 0 ? :upward : :downward, factors: factors }
    end

    private

    # A plain 14-period mean of gains and losses, not Wilder's smoothing: every
    # score already stored was computed this way, so the choice is load-bearing.
    def rsi_14(closes)
      return nil if closes.size < 15

      deltas = closes.last(15).each_cons(2).map { |previous, current| current - previous }
      avg_gain = deltas.sum { |delta| delta.positive? ? delta : 0.0 } / 14.0
      avg_loss = deltas.sum { |delta| delta.negative? ? delta.abs : 0.0 } / 14.0
      return avg_gain.zero? ? 50.0 : 100.0 if avg_loss.zero?

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
        ema = ((val - ema) * multiplier) + ema
        series << ema
      end

      series
    end

    # The fast EMA seeds `long - short` values earlier than the slow one, so it
    # is trimmed to the overlap before the two can be read against each other.
    # nil when either series is too short to leave any overlap at all.
    def aligned_ema_pair(closes, short:, long:)
      fast = compute_ema_series(closes, short)
      slow = compute_ema_series(closes, long)
      return nil if fast.empty? || slow.empty?

      offset = long - short
      return nil if fast.size <= offset

      [ fast[offset..], slow ]
    end

    def macd_signal(closes)
      fast, slow = aligned_ema_pair(closes, short: 12, long: 26)
      return nil unless fast

      macd_line = fast.zip(slow).map { |fast_ema, slow_ema| fast_ema - slow_ema }
      signal_line = compute_ema_series(macd_line, 9)
      return nil if signal_line.empty?

      histogram = macd_line.last - signal_line.last
      last_price = closes.last.to_f
      return 50.0 if last_price.zero?

      # The histogram is a price difference, so it is read per-mille of the last
      # close: ±50‰ of price spans the whole 0-100 range around a neutral 50.
      normalized = (histogram / last_price) * 1000.0
      (normalized.clamp(-50, 50) + 50).clamp(0, 100)
    end

    # A missing volume is dropped, never coerced to zero: nil means the day was
    # not reported, and 0.0 asserts that nothing traded, which drags the ratio.
    def volume_trend(volumes, momentum)
      values = Array(volumes).compact.map(&:to_f)
      return nil if values.size < 20

      avg_5d = values.last(5).sum / 5.0
      avg_20d = values.last(20).sum / 20.0
      return 50.0 if avg_20d.zero?

      ratio = avg_5d / avg_20d
      # Invert ratio when bearish: high volume in downtrend = bearish signal
      ratio = 1.0 / ratio if momentum < 0 && ratio > 0
      # Normalize ratio (0.5-2.0) to 0-100
      ((ratio - 0.5) / 1.5 * 100.0).clamp(0.0, 100.0)
    end

    def ema_crossover(closes)
      fast, slow = aligned_ema_pair(closes, short: 9, long: 21)
      return nil unless fast

      last_price = closes.last.to_f
      return 50.0 if last_price.zero?

      spread = (fast.last - slow.last) / last_price * 100.0
      # A spread of ±5% of the last close spans the whole 0-100 range.
      ((spread.clamp(-5, 5) * 10.0) + 50.0).clamp(0, 100)
    end

    # RSI and momentum are always present; the other three are weighted only
    # when the series could compute them, and the divisor is the weight actually
    # gathered — a missing factor is left out, never scored as a zero.
    def blend_5_factor(rsi, momentum, macd, vol, ema)
      present = [
        [ 0.3, rsi.clamp(0, 100) ],
        [ 0.2, normalize_momentum(momentum) ],
        [ 0.2, macd ],
        [ 0.15, vol ],
        [ 0.15, ema ]
      ].reject { |_weight, value| value.nil? }

      # Accumulated left to right on purpose: Array#sum compensates float error
      # and would not reproduce the scores already stored.
      weighted = 0.0
      total_weight = 0.0
      present.each do |weight, value|
        weighted += weight * value
        total_weight += weight
      end

      (weighted / total_weight).clamp(0, 100).round
    end

    def label_for(score)
      case score
      when 0..20   then :low_score
      when 21..40  then :low_moderate
      when 41..60  then :neutral
      when 61..80  then :moderate
      when 81..90  then :high_score
      when 91..100 then :peak
      end
    end
    end
    end
  end
end
