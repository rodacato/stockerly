module MarketData
  module UseCases
    # One row per asset, overwritten — nothing reads indicator history, and an
    # appended row would need its own prune job (X16). Written by the detector
    # at each close and by the session refresh in between (D126).
    class RecordTechnicalReading < SimpleUseCase
      def call(asset:, rows:, calculated_at: Time.current)
        reading = Domain::TechnicalIndicators.current_reading(rows.map(&:close), bars: Queries::PriceSeries.closed_bars(rows))
        return if reading.blank?

        record = asset.technical_reading || asset.build_technical_reading
        record.update!(calculated_at: calculated_at, readings: reading)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.warn("TechnicalReading failed for #{asset.symbol}: #{e.message}")
      end
    end
  end
end
