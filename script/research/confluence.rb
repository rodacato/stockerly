# Does the mean-reversion light predict anything on this portfolio's own
# history? D3 gates the confluence engine on a discovery card, and the card
# cannot be answered without a forward-return measurement that nobody has run.
#
# Light 1 is RSI(14) < 30 AND close below the lower Bollinger band, the
# definition already written down in the design prompt. Its forward returns are
# compared against the same asset's unconditional base rate over the same
# horizons — a signal that only matches the base rate has told you nothing.
#
#   DATABASE_PREFIX=prodmirror bin/rails runner script/research/confluence.rb

HORIZONS = [ 5, 10, 20 ].freeze
OVERSOLD = 30
OVERBOUGHT = 70
TREND_PERIODS = [ 50, 200 ].freeze

Indicators = MarketData::Domain::TechnicalIndicators

def readings_for(closes)
  closes.each_index.map do |i|
    window = closes[0..i]
    bands = Indicators.bollinger_bands(window)
    { rsi: Indicators.rsi(window), bb_lower: bands&.fetch(:lower), bb_upper: bands&.fetch(:upper) }
  end
end

def forward_return(closes, index, horizon)
  target = index + horizon
  return nil if target >= closes.size

  (closes[target] - closes[index]) / closes[index] * 100
end

def base_rates(closes)
  HORIZONS.to_h do |h|
    values = closes.each_index.filter_map { |i| forward_return(closes, i, h) }
    [ h, values.empty? ? nil : values.sum / values.size ]
  end
end

# Consecutive firings are the same episode seen twice: their forward windows
# overlap almost entirely, so counting each one inflates n and correlates it.
def episodes(indices, gap)
  indices.each_with_object([]) { |i, kept| kept << i if kept.empty? || i - kept.last >= gap }
end

# Light 3's own test, asked at the moment light 1 fires and never after it —
# the whole-window split below can see the future, and this one cannot.
#
# Both periods, because they answer differently: an oversold bar is almost
# always under its 50, and being under the 200 as well is the real question.
def trend_at(closes, index, period)
  sma = Indicators.sma(closes[0..index], period: period)
  return nil if sma.nil?

  closes[index] >= sma ? :above : :below
end

def describe(values)
  return "n=0" if values.empty?

  sorted = values.sort
  mean = values.sum / values.size
  median = sorted[sorted.size / 2]
  wins = values.count(&:positive?) * 100.0 / values.size
  format("n=%-4d mean %+6.2f%%  median %+6.2f%%  win %3.0f%%", values.size, mean, median, wins)
end

puts "Database: #{ActiveRecord::Base.connection_db_config.database}"

oversold = Hash.new { |h, k| h[k] = [] }
overbought = Hash.new { |h, k| h[k] = [] }
base = Hash.new { |h, k| h[k] = [] }
per_asset = []
drift = []
split = Hash.new { |h, k| h[k] = [] }
live = Hash.new { |h, k| h[k] = [] }

Asset.joins(:asset_price_histories).distinct.find_each do |asset|
  closes = MarketData::Queries::PriceSeries.for(asset).closed.map { |row| row.close.to_f }
  next if closes.size < 60

  readings = readings_for(closes)
  rates = base_rates(closes)
  HORIZONS.each { |h| base[h] << rates[h] if rates[h] }

  low_days = []
  high_days = []

  readings.each_with_index do |reading, i|
    next if reading[:rsi].nil? || reading[:bb_lower].nil?

    low_days << i if reading[:rsi] < OVERSOLD && closes[i] < reading[:bb_lower]
    high_days << i if reading[:rsi] > OVERBOUGHT && closes[i] > reading[:bb_upper]
  end

  total = ((closes.last - closes.first) / closes.first) * 100
  direction = total.negative? ? :fell : :rose

  HORIZONS.each do |h|
    episodes(low_days, h).each do |i|
      next unless (r = forward_return(closes, i, h))

      oversold[h] << r
      split[[ direction, h ]] << r

      TREND_PERIODS.each do |period|
        state = trend_at(closes, i, period)
        live[[ period, state, h ]] << r unless state.nil?
      end
    end
    episodes(high_days, h).each do |i|
      r = forward_return(closes, i, h)
      overbought[h] << r if r
    end
  end

  drift << total
  per_asset << { symbol: asset.symbol, bars: closes.size, low: episodes(low_days, 10).size,
                 high: episodes(high_days, 10).size, days: low_days.size + high_days.size }
end

puts "\nThe window this is measured in"
puts format("  %d assets, mean total move %+.1f%% over the series", drift.size, drift.sum / drift.size)
puts "  A rising window flatters whichever light points the way the market went."

puts "\nEpisodes per asset, consecutive firings collapsed"
puts format("  %-14s %6s %10s %11s", "symbol", "bars", "oversold", "overbought")
per_asset.sort_by { |r| -(r[:low] + r[:high]) }.first(15).each do |r|
  puts format("  %-14s %6d %10d %11d", r[:symbol], r[:bars], r[:low], r[:high])
end
puts "  … #{per_asset.size - 15} more"

puts "\nForward returns after the light fires, against the base rate"
HORIZONS.each do |h|
  mean_base = base[h].sum / base[h].size
  puts "\n  +#{h} trading days   (base rate #{format('%+.2f%%', mean_base)}, averaged over every bar)"
  puts "    oversold    #{describe(oversold[h])}"
  puts "    overbought  #{describe(overbought[h])}"
end

puts "\nThe oversold light, split by where the asset went over the whole window"
puts "  Diagnostic only — this split can see the future, so it is not a rule."
HORIZONS.each do |h|
  puts "\n  +#{h} trading days"
  puts "    on assets that rose  #{describe(split[[ :rose, h ]])}"
  puts "    on assets that fell  #{describe(split[[ :fell, h ]])}"
end

puts "\nThe same split, asked on the day the light fired: close against its SMA"
puts "  A rule, not a diagnostic — every input existed on the day. Read the n:"
puts "  a starved row is the corpus talking, not the signal."
TREND_PERIODS.each do |period|
  HORIZONS.each do |h|
    above = live[[ period, :above, h ]]
    below = live[[ period, :below, h ]]
    puts "\n  SMA(#{period}), +#{h} trading days"
    puts "    above  #{describe(above)}"
    puts "    below  #{describe(below)}"
  end
end

puts "\nAssets: #{per_asset.size}  ·  oversold events: #{per_asset.sum { |r| r[:low] }}  ·  overbought events: #{per_asset.sum { |r| r[:high] }}"
