module Administration
  module UseCases
    module Assets
      class SearchTicker < ApplicationUseCase
        QUOTE_TYPE_MAP = {
          "EQUITY" => "stock",
          "ETF" => "etf",
          "CRYPTOCURRENCY" => "crypto",
          "INDEX" => "index",
          "MUTUALFUND" => "etf"
        }.freeze

        REGION_COUNTRY_MAP = {
          "United States" => "US",
          "United Kingdom" => "GB",
          "Germany" => "DE", "Frankfurt" => "DE",
          "France" => "FR", "Paris" => "FR",
          "Japan" => "JP", "Tokyo" => "JP",
          "Canada" => "CA", "Toronto" => "CA",
          "Brazil" => "BR", "Brazil/Sao Paolo" => "BR",
          "Mexico" => "MX",
          "China" => "CN", "Shanghai" => "CN", "Shenzhen" => "CN",
          "Hong Kong" => "HK",
          "South Korea" => "KR",
          "Taiwan" => "TW",
          "India" => "IN"
        }.freeze

        def call(query:)
          return Failure([ :validation, "Query must be at least 2 characters" ]) if query.blank? || query.strip.length < 2

          gateway = MarketData::Gateways::AlphaVantageGateway.new
          results = yield gateway.search_tickers(query.strip)

          mapped = results.map { |r| map_result(r) }

          Success(mapped)
        end

        private

        def map_result(result)
          region = result[:exchange]

          {
            symbol: result[:symbol],
            name: result[:name],
            asset_type: QUOTE_TYPE_MAP[result[:quote_type]] || "stock",
            exchange: region,
            country: REGION_COUNTRY_MAP[region]
          }
        end
      end
    end
  end
end
