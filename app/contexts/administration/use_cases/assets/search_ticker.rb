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

        # Keyed on whatever the provider calls the venue. Yahoo sends an
        # exchange display name; the region names below are Alpha Vantage's.
        REGION_COUNTRY_MAP = {
          "NASDAQ" => "US", "NYSE" => "US", "NYSEArca" => "US",
          "NYSE American" => "US", "BATS Trading" => "US", "OTC Markets" => "US",
          "XETRA" => "DE", "Munich" => "DE", "Dusseldorf Stock Exchange" => "DE",
          "London" => "GB", "Mexico City" => "MX",
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
          results = yield MarketData::UseCases::SearchTickers.call(query: query)

          mapped = results.map { |r| map_result(r) }

          Success(mapped)
        end

        private

        def map_result(result)
          region = result[:exchange]
          country = REGION_COUNTRY_MAP[region]

          {
            symbol: result[:symbol],
            name: result[:name],
            asset_type: QUOTE_TYPE_MAP[result[:quote_type]] || "stock",
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
