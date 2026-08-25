module MarketData
  module Queries
    # Public read API: RSI as it stood on given past dates, recomputed from the
    # stored closes. Persisted observations only exist where a threshold was
    # crossed, so a purchase on an ordinary day has none — this fills that gap.
    #
    # Dates with too little history before them are simply absent from the
    # result. BackfillPriceHistoryJob fetches 30 days and the daily sync
    # accumulates from there, so a purchase predating the asset's sync has no
    # answer, and inventing one would be worse than the gap.
    class RsiOnDates
      PERIOD = 14

      def self.call(asset:, dates:)
        dates = Array(dates).compact.uniq
        return {} if dates.empty?

        closes = asset.asset_price_histories.order(:date).pluck(:date, :close)
        return {} if closes.size < PERIOD + 1

        dates.index_with { |date| rsi_upto(closes, date) }.compact
      end

      def self.rsi_upto(closes, date)
        upto = closes.take_while { |close_date, _| close_date <= date }.map(&:last)
        Domain::TechnicalIndicators.rsi(upto)
      end
      private_class_method :rsi_upto
    end
  end
end
