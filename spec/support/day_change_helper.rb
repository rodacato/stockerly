# ADR-021: the day change screens render is computed from two daily closes, so
# a spec that expects a percentage on screen gives the asset the history that
# produces it rather than setting the provider's column.
module DayChangeHelper
  def with_day_change(asset, percent, close: nil)
    close = (close || asset.current_price || 100).to_d
    previous = close / (1 + (percent.to_d / 100))

    create(:asset_price_history, asset: asset, date: Date.current - 1,
                                 open: previous, high: previous, low: previous, close: previous)
    create(:asset_price_history, asset: asset, date: Date.current,
                                 open: close, high: close, low: close, close: close)
    asset
  end
end

RSpec.configure do |config|
  config.include DayChangeHelper
end
