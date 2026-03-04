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

        EXCHANGE_COUNTRY_MAP = {
          "NMS" => "US", "NYQ" => "US", "NGM" => "US", "NCM" => "US",
          "PCX" => "US", "BTS" => "US", "ASE" => "US",
          "MEX" => "MX",
          "LSE" => "GB", "IOB" => "GB",
          "TYO" => "JP", "JPX" => "JP",
          "FRA" => "DE", "GER" => "DE",
          "PAR" => "FR",
          "TOR" => "CA", "CNQ" => "CA",
          "SAO" => "BR",
          "SHH" => "CN", "SHZ" => "CN",
          "HKG" => "HK",
          "KSC" => "KR", "KOE" => "KR",
          "TAI" => "TW",
          "CCC" => nil
        }.freeze

        EXCHANGE_DISPLAY_MAP = {
          "NMS" => "NASDAQ", "NYQ" => "NYSE", "NGM" => "NASDAQ", "NCM" => "NASDAQ",
          "PCX" => "NYSE ARCA", "BTS" => "BATS", "ASE" => "AMEX",
          "MEX" => "BMV",
          "LSE" => "LSE", "IOB" => "LSE",
          "TYO" => "TSE", "FRA" => "FRA", "PAR" => "EPA",
          "TOR" => "TSX", "SAO" => "B3",
          "CCC" => "CRYPTO"
        }.freeze

        def call(query:)
          return Failure([ :validation, "Query must be at least 2 characters" ]) if query.blank? || query.strip.length < 2

          gateway = MarketData::Gateways::YahooFinanceGateway.new
          results = yield gateway.search_tickers(query.strip)

          mapped = results.map { |r| map_result(r) }

          Success(mapped)
        end

        private

        def map_result(result)
          exchange_code = result[:exchange]

          {
            symbol: result[:symbol],
            name: result[:name],
            asset_type: QUOTE_TYPE_MAP[result[:quote_type]] || "stock",
            exchange: EXCHANGE_DISPLAY_MAP[exchange_code] || result[:exchange_display] || exchange_code,
            country: EXCHANGE_COUNTRY_MAP[exchange_code]
          }
        end
      end
    end
  end
end
