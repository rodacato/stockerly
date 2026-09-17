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

        # Keyed on the exchange display name Yahoo's search sends.
        REGION_COUNTRY_MAP = {
          "NASDAQ" => "US", "NYSE" => "US", "NYSEArca" => "US",
          "NYSE American" => "US", "BATS Trading" => "US", "OTC Markets" => "US",
          "XETRA" => "DE", "Munich" => "DE", "Dusseldorf Stock Exchange" => "DE", "Frankfurt" => "DE",
          "London" => "GB", "Paris" => "FR", "Toronto" => "CA",
          "Mexico" => "MX", "Mexico City" => "MX",
          "Tokyo" => "JP", "Shanghai" => "CN", "Shenzhen" => "CN",
          "Hong Kong" => "HK", "Taiwan" => "TW"
        }.freeze

        def call(query:)
          results = yield MarketData::UseCases::SearchTickers.call(query: query)

          # Options, futures and currency pairs come back too; none of them is a
          # type the catalogue can hold.
          mapped = results.select { |r| QUOTE_TYPE_MAP.key?(r[:quote_type]) }.map { |r| map_result(r) }

          Success(mapped)
        end

        private

        def map_result(result)
          region = result[:exchange]
          country = REGION_COUNTRY_MAP[region]

          {
            symbol: result[:symbol],
            name: result[:name],
            asset_type: QUOTE_TYPE_MAP.fetch(result[:quote_type]),
            exchange: region,
            country: country,
            sector: result[:sector],
            currency: derive_currency(result[:currency], country)
          }
        end

        # Yahoo's search omits currency entirely, so country carries it. A venue
        # nobody mapped lands on USD, which is right for every venue listed here
        # except Mexico's, and Mexico's is mapped.
        def derive_currency(provider_currency, country)
          return provider_currency if provider_currency.present?
          return "MXN" if country == "MX"

          "USD"
        end
      end
    end
  end
end
