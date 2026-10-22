module MarketData
  module Queries
    # ADR-031: USD/MXN in force on a date, with the date it is really for and
    # who published it — the same walk-back the trades are valued with.
    class FxQuote
      # @api public
      def self.call(date: Date.current)
        quote = FxRateHistory.quote_on(base: "USD", quote: "MXN", date: date)
        return nil unless quote

        { base: "USD", quote: "MXN", rate: quote.rate, rate_date: quote.rate_date, source: quote.source }.freeze
      end
    end
  end
end
