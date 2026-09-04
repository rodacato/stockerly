# Measures the volatility-calibrated family against real history, so the board's
# eight InvestAnswers cards can be decided on evidence rather than on taste.
#
# ATR is the only indicator implemented here; RSI, SMA and Bollinger come from
# MarketData::Domain::TechnicalIndicators, which the suite already covers. It
# stays out of that class on purpose: the ATR card owns that seam.
#
#   DATABASE_PREFIX=prodmirror bin/rails runner script/research/indicators.rb

module Research
  # Wilder's Average True Range (1978). The smoothing is the recursion, not a
  # simple mean — a mean over the same window is a different indicator.
  module Wilder
    module_function

    def true_ranges(bars)
      bars.each_cons(2).map do |prev, cur|
        [ cur[:high] - cur[:low],
          (cur[:high] - prev[:close]).abs,
          (cur[:low] - prev[:close]).abs ].max.to_f
      end
    end

    def atr(bars, period: 14)
      return nil if bars.size < period + 1

      trs = true_ranges(bars)
      seed = trs.first(period).sum / period.to_f
      trs.drop(period).reduce(seed) { |avg, tr| ((avg * (period - 1)) + tr) / period.to_f }
    end

    # Every ATR the series can support, aligned to the bar each one closes on.
    def series(bars, period: 14)
      return [] if bars.size < period + 1

      trs = true_ranges(bars)
      avg = trs.first(period).sum / period.to_f
      out = [ [ bars[period][:date], avg ] ]

      trs.drop(period).each_with_index do |tr, i|
        avg = ((avg * (period - 1)) + tr) / period.to_f
        out << [ bars[period + 1 + i][:date], avg ]
      end
      out
    end
  end

  # Assertions that pin Wilder's definition rather than this implementation of
  # it. A failure here invalidates every number the run goes on to print.
  module SelfCheck
    module_function

    def run
      checks = [
        [ "flat bars carry no range", flat_is_zero ],
        [ "a constant range is its own average", constant_range ],
        [ "the recursion matches one hand-applied step", recursion_step ],
        [ "Wilder differs from a simple mean while trending", differs_from_mean ],
        [ "too short is nil, never zero", short_is_nil ]
      ]

      checks.each { |name, ok| puts "  #{ok ? '✓' : '✗'} #{name}" }
      abort "\nSelf-check failed — every figure below would be untrustworthy." if checks.any? { |_, ok| !ok }
    end

    def bar(high, low, close, date = Date.new(2026, 1, 1))
      { high: high, low: low, close: close, date: date }
    end

    def flat_is_zero
      Wilder.atr(Array.new(30) { bar(10.0, 10.0, 10.0) })&.zero?
    end

    def constant_range
      bars = Array.new(30) { bar(11.0, 9.0, 10.0) }
      (Wilder.atr(bars) - 2.0).abs < 1e-9
    end

    def recursion_step
      bars = Array.new(30) { |i| bar(10.0 + i, 9.0 + i, 9.5 + i) }
      before = Wilder.atr(bars[0..-2])
      last_tr = Wilder.true_ranges(bars.last(2)).first
      expected = ((before * 13) + last_tr) / 14.0

      (Wilder.atr(bars) - expected).abs < 1e-9
    end

    def differs_from_mean
      bars = Array.new(40) { |i| bar(10.0 + (i * 2), 9.0 + i, 9.5 + i) }
      mean = Wilder.true_ranges(bars).last(14).sum / 14.0

      (Wilder.atr(bars) - mean).abs > 0.01
    end

    def short_is_nil
      Wilder.atr(Array.new(14) { bar(11.0, 9.0, 10.0) }).nil?
    end
  end
end

def bars_for(asset)
  MarketData::Queries::PriceSeries.for(asset).closed.filter_map do |row|
    next if row.high.nil? || row.low.nil?

    { date: row.date, high: row.high.to_f, low: row.low.to_f, close: row.close.to_f }
  end
end

puts "Database: #{ActiveRecord::Base.connection_db_config.database}"
puts "\nSelf-check"
Research::SelfCheck.run

rows = Asset.joins(:asset_price_histories).distinct.filter_map do |asset|
  bars = bars_for(asset)
  atr = Research::Wilder.atr(bars)
  next if atr.nil?

  last = bars.last[:close]
  { symbol: asset.symbol, type: asset.asset_type, bars: bars.size, close: last,
    atr: atr, pct: last.zero? ? nil : (atr / last * 100) }
end.sort_by { |r| -r[:pct].to_f }

puts "\nATR(14) on #{rows.size} assets — the daily range each one actually moves"
puts format("  %-14s %-7s %6s %12s %10s %8s", "symbol", "type", "bars", "close", "atr", "% price")
rows.each do |r|
  puts format("  %-14s %-7s %6d %12.2f %10.4f %7.2f%%", r[:symbol], r[:type], r[:bars], r[:close], r[:atr], r[:pct])
end

by_type = rows.group_by { |r| r[:type] }.transform_values { |rs| rs.sum { |r| r[:pct] } / rs.size }
puts "\nMean daily range by type"
by_type.sort_by { |_, pct| -pct }.each { |type, pct| puts format("  %-8s %5.2f%%", type, pct) }
