module MarketData
  module UseCases
    # Fills CetesRateHistory from Banxico's auction series (D28). Mirrors
    # SyncFxHistory: one ranged request instead of one per auction.
    class SyncCetesHistory < ApplicationUseCase
      DEFAULT_LOOKBACK = 30
      TERM = "28"

      def call(term: TERM, from: nil, to: Date.current, gateway: nil)
        from ||= to - DEFAULT_LOOKBACK
        gateway ||= Gateways::BanxicoGateway.new

        auctions = yield gateway.fetch_auction_series(term: term, from: from, to: to)

        Success(stored: persist(term, auctions), from: from, to: to)
      rescue Gateways::ApiKeyNotConfiguredError => e
        Failure([ :not_configured, e.message ])
      end

      private

      def persist(term, auctions)
        auctions.count do |auction|
          next false if auction[:auction_date].blank?

          CetesRateHistory.record(
            term: term,
            date: auction[:auction_date],
            rate: auction[:yield_rate],
            source: "banxico"
          )
        end
      end
    end
  end
end
