# Audits the indicators against their own definitions, on a real ten-year
# series rather than on a fixture. Every claim it prints is a comparison, not a
# reading of the code.
#
#   DATABASE_PREFIX=prodmirror bin/rails runner script/research/indicator_audit.rb [SYMBOL]

SYMBOL = (ARGV.first || "NVDA").upcase
Indicators = MarketData::Domain::TechnicalIndicators

# Wilder's RSI: the averages are smoothed across the whole series, seeded once.
# This is what 70/30 was calibrated against and what a broker's chart draws.
def wilder_rsi_series(closes, period: 14)
  deltas = closes.each_cons(2).map { |a, b| b - a }
  return [] if deltas.size < period

  gains = deltas.map { |d| d.positive? ? d : 0.0 }
  losses = deltas.map { |d| d.negative? ? d.abs : 0.0 }

  avg_gain = gains.first(period).sum / period.to_f
  avg_loss = losses.first(period).sum / period.to_f
  out = [ [ period, rsi_from(avg_gain, avg_loss) ] ]

  gains.drop(period).each_with_index do |gain, i|
    loss = losses[period + i]
    avg_gain = ((avg_gain * (period - 1)) + gain) / period.to_f
    avg_loss = ((avg_loss * (period - 1)) + loss) / period.to_f
    out << [ period + 1 + i, rsi_from(avg_gain, avg_loss) ]
  end

  out
end

def rsi_from(avg_gain, avg_loss)
  return 50.0 if avg_gain.zero? && avg_loss.zero?
  return 100.0 if avg_loss.zero?

  100.0 - (100.0 / (1.0 + (avg_gain / avg_loss)))
end

def summarise(label, values)
  return puts("  #{label}: none") if values.empty?

  sorted = values.sort
  puts format("  %-28s n=%-5d mean %6.2f  median %6.2f  p95 %6.2f  max %6.2f",
              label, values.size, values.sum / values.size, sorted[sorted.size / 2],
              sorted[(sorted.size * 0.95).to_i], sorted.last)
end

asset = Asset.find_by(symbol: SYMBOL) or abort "No asset #{SYMBOL}"
rows = MarketData::Queries::PriceSeries.for(asset).closed.to_a
closes = rows.map { |r| r.close.to_f }
abort "#{SYMBOL} has only #{closes.size} bars — deepen it first" if closes.size < 300

puts "#{SYMBOL}: #{closes.size} bars, #{rows.first.date} .. #{rows.last.date}"

# ── RSI: the shipped one against Wilder's ──────────────────────────────────
shipped = closes.each_index.filter_map { |i| [ i, Indicators.rsi(closes[0..i]) ] if i >= 14 }.to_h
wilder = wilder_rsi_series(closes).to_h

common = shipped.keys & wilder.keys
gaps = common.map { |i| (shipped[i] - wilder[i]).abs }

puts "\nRSI(14) — what ships against Wilder's definition"
summarise("absolute difference", gaps)

shipped_over = common.count { |i| shipped[i] >= 70 }
wilder_over = common.count { |i| wilder[i] >= 70 }
shipped_under = common.count { |i| shipped[i] <= 30 }
wilder_under = common.count { |i| wilder[i] <= 30 }
disagree_over = common.count { |i| (shipped[i] >= 70) != (wilder[i] >= 70) }
disagree_under = common.count { |i| (shipped[i] <= 30) != (wilder[i] <= 30) }

puts format("  overbought days   shipped %4d · Wilder %4d · disagree on %d of %d (%.1f%%)",
            shipped_over, wilder_over, disagree_over, common.size, disagree_over * 100.0 / common.size)
puts format("  oversold days     shipped %4d · Wilder %4d · disagree on %d of %d (%.1f%%)",
            shipped_under, wilder_under, disagree_under, common.size, disagree_under * 100.0 / common.size)

# ── The same number read two opposite ways ────────────────────────────────
puts "\nWhat a high RSI means, in the two places that read it"
hot = common.select { |i| shipped[i] >= 70 }
scores = hot.filter_map do |i|
  window = closes[[ 0, i - 59 ].max..i]
  MarketData::Domain::TrendScoreCalculator.calculate(closes: window)&.fetch(:score)
end
summarise("TrendScore on overbought days", scores.map(&:to_f))
puts "  IndicatorSignals calls those days :overbought — a state the detail draws as a warning."

# ── The alert that names one indicator and reads another ──────────────────
puts "\nAn `rsi_overbought` rule at 70, as worded against as evaluated"
puts "  AlertEvaluator reads latest_trend_score; TriggerNotice says \"RSI(14) >= 70\"."

both = (60...closes.size).filter_map do |i|
  score = MarketData::Domain::TrendScoreCalculator.calculate(closes: closes[(i - 59)..i])&.fetch(:score)
  next if score.nil? || shipped[i].nil?

  [ shipped[i], score.to_f ]
end

by_rsi = both.count { |rsi, _| rsi >= 70 }
by_score = both.count { |_, score| score >= 70 }
disagree = both.count { |rsi, score| (rsi >= 70) != (score >= 70) }
false_fire = both.count { |rsi, score| score >= 70 && rsi < 70 }
missed = both.count { |rsi, score| rsi >= 70 && score < 70 }

puts format("  days RSI(14) >= 70        %4d", by_rsi)
puts format("  days TrendScore >= 70     %4d", by_score)
puts format("  the rule fires and RSI does not say overbought   %4d", false_fire)
puts format("  RSI says overbought and the rule stays silent    %4d", missed)
puts format("  disagreement                                     %4d of %d (%.1f%%)",
            disagree, both.size, disagree * 100.0 / both.size)

# ── Fixed thresholds, on an asset that moves 3% a day ─────────────────────
puts "\nFactors whose range is a constant, measured against this asset's own moves"
seven_day = closes.each_cons(8).map { |w| (w.last - w.first) / w.first * 100.0 }
saturated = seven_day.count { |m| m.abs >= 20 }
puts format("  momentum clamps at +-20%% over 7 days: reached on %d of %d bars (%.1f%%)",
            saturated, seven_day.size, saturated * 100.0 / seven_day.size)

spreads = (60...closes.size).map do |i|
  window = closes[0..i]
  e9 = window.last(60)
  ema = ->(vals, p) { m = 2.0 / (p + 1); v = vals.first(p).sum / p.to_f; vals[p..].each { |x| v = ((x - v) * m) + v }; v }
  ((ema.call(e9, 9) - ema.call(e9, 21)) / window.last * 100.0).abs
end
saturated_ema = spreads.count { |s| s >= 5 }
puts format("  ema spread clamps at +-5%% of price: reached on %d of %d bars (%.1f%%)",
            saturated_ema, spreads.size, saturated_ema * 100.0 / spreads.size)
