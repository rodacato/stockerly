module MarketData
  module Queries
    # Public read API: what a market index returned between two dates, as the
    # change of its closes — a price index, so dividends are not in it.
    #
    # ADR-002: Trading asks this rather than reaching into MarketIndexHistory.
    # A close more than STALE_DAYS older than the date it stands for answers a
    # different question (ADR-0023), so the figure is nil instead.
    class IndexReturn
      STALE_DAYS = 7

      def self.call(symbol:, from:, to:)
        return nil if from >= to

        index = MarketIndex.find_by(symbol: symbol)
        return nil unless index

        opening = close_on(index, from)
        closing = close_on(index, to)
        return nil if opening.nil? || closing.nil?

        (((closing / opening) - 1) * 100).to_f
      end

      def self.close_on(index, date)
        index.market_index_histories
             .where(interval: "1d", date: (date - STALE_DAYS)..date)
             .order(date: :desc).limit(1).pick(:close_value)
      end
      private_class_method :close_on
    end
  end
end
