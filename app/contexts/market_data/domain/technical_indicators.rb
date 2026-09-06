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
      # The keys a persisted reading may carry. Like TrendScoreCalculator's
      # FACTORS, this minus a row's keys is what that reading could not compute
      # — absence is the signal, never a zero.
      READINGS = %i[close rsi sma_50 sma_200 bb_upper bb_middle bb_lower atr].freeze
      # Named because the chart prints it — a pane labelled `RSI (14)` computed
      # over some other window is the drift this constant exists to prevent.
      RSI_PERIOD = 14

      class << self
        # Every indicator this object computes, as one dated reading. The single
        # shape persisted to `technical_readings`; nothing else writes that table.
        #
        # `bars` are separate from `closes` because they must be: high and low
        # grow all session, so ATR reads closed bars only, while today's close
        # is the current price and is exactly what RSI should see (#483). Pass
        # no bars and the reading simply carries no ATR.
        def current_reading(closes, bars: [])
          bands = bollinger_bands(closes)

          {
            close: closes.last&.to_f&.round(4),
            rsi: rsi(closes),
            sma_50: sma(closes, period: 50),
            sma_200: sma(closes, period: 200),
            bb_upper: bands&.fetch(:upper),
            bb_middle: bands&.fetch(:middle),
            bb_lower: bands&.fetch(:lower),
            atr: atr(bars)
          }.compact
        end

        # Wilder's RSI: the averages are seeded once and smoothed across the
        # whole series, which is the definition 70 and 30 were calibrated
        # against. A plain mean of the last fourteen deltas is a different
        # indicator — on ten years of NVDA the two sit 6.45 points apart and
        # disagree about "oversold" four times out of five.
        #
        # The last value of the series, so a chart and a card reading the same
        # closes cannot report different numbers.
        def rsi(closes, period: RSI_PERIOD)
          rsi_series(closes, period: period).last
        end

        # Wilder's smoothing already carries its state forward, so the whole
        # series costs one pass. Re-running `rsi` per date would be quadratic:
        # on the deepest asset on file that is 2952 whole-series smoothings to
        # draw one line.
        #
        # Aligned with `closes` and `nil` until the seed window closes — absence
        # is what "not enough history yet" looks like, never a zero.
        def rsi_series(closes, period: RSI_PERIOD)
          values = Array.new(closes.size)
          return values if closes.size < period + 1

          deltas = closes.each_cons(2).map { |a, b| b.to_f - a.to_f }
          gains  = deltas.map { |d| d.positive? ? d : 0.0 }
          losses = deltas.map { |d| d.negative? ? d.abs : 0.0 }

          avg_gain = gains.first(period).sum / period.to_f
          avg_loss = losses.first(period).sum / period.to_f
          values[period] = wilder_index(avg_gain, avg_loss)

          gains.drop(period).each_with_index do |gain, index|
            avg_gain = ((avg_gain * (period - 1)) + gain) / period.to_f
            avg_loss = ((avg_loss * (period - 1)) + losses[period + index]) / period.to_f
            values[period + index + 1] = wilder_index(avg_gain, avg_loss)
          end

          values
        end

        # Wilder's Average True Range (1978), over bars carrying high, low and
        # close, oldest first. True range counts the gap between sessions, which
        # is why Bollinger's standard deviation of closes is not a substitute:
        # a limit-down open that never trades through yesterday's range is
        # invisible to one and the whole point of the other.
        #
        # Smoothed by the same recursion as RSI, not by a mean over the window.
        def atr(bars, period: 14)
          return nil if bars.size < period + 1

          ranges = true_ranges(bars)
          seed = ranges.first(period).sum / period.to_f

          ranges.drop(period).reduce(seed) { |avg, range| ((avg * (period - 1)) + range) / period.to_f }.round(4)
        end

        # Simple Moving Average over the last `period` closes.
        def sma(closes, period:)
          return nil if closes.size < period

          (closes.last(period).sum(&:to_f) / period.to_f).round(4)
        end

        # The bands at every date, aligned with `closes`. Each entry is computed
        # from its own window rather than from a running total: the window is
        # twenty closes, so the direct form is cheap, and it makes the last
        # entry identical to `bollinger_bands` by construction instead of by
        # floating-point luck.
        def bollinger_series(closes, period: 20, stddev: 2.0)
          Array.new(closes.size) do |index|
            next if index < period - 1

            bollinger_bands(closes[(index - period + 1)..index], period: period, stddev: stddev)
          end
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
            upper:  (middle + (stddev * std)).round(4),
            middle: middle.round(4),
            lower:  (middle - (stddev * std)).round(4)
          }
        end

        private

        def wilder_index(avg_gain, avg_loss)
          return 50.0  if avg_gain.zero? && avg_loss.zero?
          return 100.0 if avg_loss.zero?

          rs = avg_gain / avg_loss
          (100.0 - (100.0 / (1.0 + rs))).round(2)
        end

        # Each bar's range measured against the previous close, so an opening
        # gap counts as movement rather than as the sliver traded after it.
        def true_ranges(bars)
          bars.each_cons(2).map do |previous, current|
            [ current[:high] - current[:low],
              (current[:high] - previous[:close]).abs,
              (current[:low] - previous[:close]).abs ].max.to_f
          end
        end
      end
    end
  end
end
