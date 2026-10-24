module PriceHistoryHelpers
  # Hundreds of closes in one INSERT; the model has no callbacks a factory would run.
  def insert_price_history(asset, rows)
    defaults = attributes_for(:asset_price_history)
    AssetPriceHistory.insert_all!(rows.map { |row| defaults.merge(asset_id: asset.id, **row) })
  end
end

RSpec.configure do |config|
  config.include PriceHistoryHelpers
end
