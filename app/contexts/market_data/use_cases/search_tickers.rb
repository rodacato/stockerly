module MarketData
  module UseCases
    # Public interface of the MarketData context for ticker search.
    # Wraps the Alpha Vantage gateway so other contexts (Administration)
    # don't reach into infrastructure directly. Anti-corruption layer at
    # the use-case level — formal pattern to be documented in ADR-002
    # (Sprint 5 architectural sprint).
    class SearchTickers < ApplicationUseCase
      def call(query:)
        return Failure([ :validation, "Query must be at least 2 characters" ]) if query.blank? || query.strip.length < 2

        Gateways::AlphaVantageGateway.new.search_tickers(query.strip)
      end
    end
  end
end
