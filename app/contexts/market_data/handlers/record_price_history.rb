module MarketData
  # Records daily OHLCV data in AssetPriceHistory when a price update occurs.
  # Creates a new record for today or updates existing high/low/close values.
  class RecordPriceHistory
    def self.call(event)
      asset_id  = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
      new_price = (event.is_a?(Hash) ? event[:new_price] : event.new_price).to_d

      today = Date.current
      existing = AssetPriceHistory.find_by(asset_id: asset_id, date: today)

      if existing
        existing.update!(
          close: new_price,
          high: [ existing.high, new_price ].max,
          low: [ existing.low, new_price ].min
        )
      else
        AssetPriceHistory.create!(
          asset_id: asset_id,
          date: today,
          open: new_price,
          high: new_price,
          low: new_price,
          close: new_price
        )
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      # Ignore race conditions on concurrent upserts
    end
  end
end
