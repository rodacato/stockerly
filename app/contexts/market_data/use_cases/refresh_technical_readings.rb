module MarketData
  module UseCases
    # The reading between closes (D126): today's close is the price of the
    # moment, as #483 reads it, and no event is detected — a crossing on an
    # unfinished bar could revert by the close and the dedup would keep it.
    class RefreshTechnicalReadings < SimpleUseCase
      def call
        refreshed = 0
        Asset.where.not(current_price: nil).where.not(asset_type: :fixed_income).find_each do |asset|
          rows = Queries::PriceSeries.for(asset).latest(DetectTechnicalObservations::WINDOW_SIZE)
          refreshed += 1 if RecordTechnicalReading.call(asset: asset, rows: rows)
        end
        refreshed
      end
    end
  end
end
