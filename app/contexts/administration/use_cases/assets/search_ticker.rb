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
            currency: derive_currency(result[:currency], country)
          }
        end

        # Alpha Vantage SYMBOL_SEARCH usually includes currency directly. Fall back to
        # country for the rare cases where the provider omits it. asset_type isn't a
        # signal here because the gateway never emits CRYPTOCURRENCY or fixed_income
        # types from a ticker search.
        def derive_currency(provider_currency, country)
          return provider_currency if provider_currency.present?
          return "MXN" if country == "MX"

          "USD"
        end
      end
    end
  end
end
