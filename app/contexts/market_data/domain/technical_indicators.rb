module MarketData
  module Domain
    # Pure stateless technical-indicator calculator for the "Notable
    # Observations" detector (#40 JTBD #6). Receives an array of closing
    # prices (oldest → newest). No DB reads, no I/O, no side effects.
    #
    # Indicators here are scoped to what the detection job needs (RSI(14),
    # SMA50, SMA200, Bollinger Bands 20×2σ). Indicators that the TrendScore
    # path already covers (MACD, EMA crossover, volume trend) stay in
    # TrendScoreCalculator — duplicating them here would invite drift.
    class TechnicalIndicators
      class << self
        # RSI for the last close. Returns nil if size < period + 1.
        def rsi(closes, period: 14)
          return nil if closes.size < period + 1

          deltas = closes.last(period + 1).each_cons(2).map { |a, b| b.to_f - a.to_f }
          gains  = deltas.map { |d| d.positive? ? d : 0.0 }
          losses = deltas.map { |d| d.negative? ? d.abs : 0.0 }

          avg_gain = gains.sum / period.to_f
          avg_loss = losses.sum / period.to_f
          return 50.0  if avg_gain.zero? && avg_loss.zero?
          return 100.0 if avg_loss.zero?

          rs = avg_gain / avg_loss
          (100.0 - (100.0 / (1.0 + rs))).round(2)
        end

        # Simple Moving Average over the last `period` closes.
        def sma(closes, period:)
          return nil if closes.size < period

          (closes.last(period).sum(&:to_f) / period.to_f).round(4)
        end

        # Bollinger Bands (default 20-period, 2σ). Returns `nil` when
        # insufficient data, otherwise `{ upper:, middle:, lower: }`.
        def bollinger_bands(closes, period: 20, stddev: 2.0)
          return nil if closes.size < period

          window = closes.last(period).map(&:to_f)
          middle = window.sum / period.to_f
          variance = window.sum { |c| (c - middle)**2 } / period.to_f
          std = Math.sqrt(variance)

          {
            upper:  (middle + stddev * std).round(4),
            middle: middle.round(4),
            lower:  (middle - stddev * std).round(4)
          }
        end
      end
    end
  end
end
