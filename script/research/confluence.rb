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

  HORIZONS.each do |h|
    episodes(low_days, h).each { |i| (r = forward_return(closes, i, h)) && oversold[h] << r }
    episodes(high_days, h).each { |i| (r = forward_return(closes, i, h)) && overbought[h] << r }
  end

  drift << (closes.last - closes.first) / closes.first * 100
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

puts "\nAssets: #{per_asset.size}  ·  oversold events: #{per_asset.sum { |r| r[:low] }}  ·  overbought events: #{per_asset.sum { |r| r[:high] }}"
