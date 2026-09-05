# The two theses a one-year corpus could not test at all, plus the regime the
# ten-year one actually is. Thesis 4 needs a twelve-month lookback and monthly
# rebalances; the Mayer Multiple needs two hundred bars before its first value.
#
#   DATABASE_PREFIX=prodmirror bin/rails runner script/research/deep_corpus.rb

LOOKBACK = 252
REBALANCE = 21
MAYER_PERIOD = 200

def series
  @series ||= Asset.joins(:asset_price_histories).distinct.filter_map do |asset|
    rows = MarketData::Queries::PriceSeries.for(asset).closed.pluck(:date, :close)
    next if rows.size < LOOKBACK + REBALANCE

    [ asset.symbol, rows.to_h { |date, close| [ date, close.to_f ] } ]
  end.to_h
end

def describe(label, values)
  return puts("  #{label}: n=0") if values.empty?

  sorted = values.sort
  puts format("  %-34s n=%-5d mean %+7.2f%%  median %+7.2f%%  win %3.0f%%",
              label, values.size, values.sum / values.size, sorted[sorted.size / 2],
              values.count(&:positive?) * 100.0 / values.size)
end

puts "Database: #{ActiveRecord::Base.connection_db_config.database}"
puts "\nThe window, stated before anything is concluded from it"
spans = series.values.map { |prices| ((prices.values.last - prices.values.first) / prices.values.first) * 100 }
sorted = spans.sort
puts format("  %d assets · mean %+.1f%% · median %+.1f%% · negative %d",
            spans.size, spans.sum / spans.size, sorted[sorted.size / 2], spans.count(&:negative?))
puts format("  earliest bar %s · latest %s", series.values.map { |p| p.keys.min }.min, series.values.map { |p| p.keys.max }.max)
puts "  These are the assets held in 2026, so the sample is chosen by an outcome"
puts "  it is then measured against. Read every figure below through that."

# ── Thesis 4: dual momentum ────────────────────────────────────────────────
# Antonacci: absolute momentum filters (is it rising at all), relative selects
# (which of mine is rising most). Rebalance monthly, hold the top slice.
dates = series.values.flat_map(&:keys).uniq.sort
rebalance_dates = dates.each_slice(REBALANCE).map(&:first)

held = []
absolute = []
puts "\nThesis 4 — dual momentum, #{rebalance_dates.size} rebalances"

rebalance_dates.each_cons(2) do |today, following|
  ranked = series.filter_map do |symbol, prices|
    past_date = prices.keys.select { |d| d <= today - LOOKBACK }.max
    next unless past_date && prices[today] && prices[following]

    [ symbol, ((prices[today] - prices[past_date]) / prices[past_date]) * 100, prices ]
  end
  next if ranked.size < 5

  top = ranked.max_by(5) { |_, momentum, _| momentum }
  # Absolute momentum: only hold what is up over the lookback at all.
  positive = top.select { |_, momentum, _| momentum.positive? }

  held.concat(top.map { |_, _, prices| ((prices[following] - prices[today]) / prices[today]) * 100 })
  absolute.concat(positive.map { |_, _, prices| ((prices[following] - prices[today]) / prices[today]) * 100 })
end

every_month = rebalance_dates.each_cons(2).flat_map do |today, following|
  series.filter_map do |_, prices|
    next unless prices[today] && prices[following]

    ((prices[following] - prices[today]) / prices[today]) * 100
  end
end

describe("holding everything (base rate)", every_month)
describe("top 5 by 12-month momentum", held)
describe("top 5, absolute momentum filter", absolute)

# ── Mayer Multiple ─────────────────────────────────────────────────────────
puts "\nThe Mayer Multiple — price over its 200-day average, and what followed"
buckets = Hash.new { |hash, key| hash[key] = [] }

series.each_value do |prices|
  closes = prices.values
  dates_for = prices.keys

  (MAYER_PERIOD...(closes.size - REBALANCE)).each do |i|
    average = closes[(i - MAYER_PERIOD + 1)..i].sum / MAYER_PERIOD.to_f
    next if average.zero?

    multiple = closes[i] / average
    forward = ((closes[i + REBALANCE] - closes[i]) / closes[i]) * 100
    bucket = case multiple
    when ..0.8 then "below 0.8 — deeply under trend"
    when ..1.0 then "0.8 to 1.0"
    when ..1.2 then "1.0 to 1.2"
    when ..2.4 then "1.2 to 2.4"
    else "above 2.4 — the level BTC studies flag"
    end
    buckets[bucket] << forward
    _ = dates_for
  end
end

[ "below 0.8 — deeply under trend", "0.8 to 1.0", "1.0 to 1.2", "1.2 to 2.4",
  "above 2.4 — the level BTC studies flag" ].each { |bucket| describe(bucket, buckets[bucket]) }
