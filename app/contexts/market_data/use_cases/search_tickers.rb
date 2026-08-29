module MarketData
  module UseCases
    # Public interface of the MarketData context for ticker search.
    #
    # Yahoo answers it, not Alpha Vantage: a search spent one of 25 daily calls
    # and needed an API key, so adding a handful of assets exhausted the day and
    # a self-hoster without a key could not search at all.
    class SearchTickers < ApplicationUseCase
      def call(query:)
        return Failure([ :validation, "Query must be at least 2 characters" ]) if query.blank? || query.strip.length < 2

        Gateways::YfinanceGateway.new.search_tickers(query.strip)
      end
    end
  end
end
