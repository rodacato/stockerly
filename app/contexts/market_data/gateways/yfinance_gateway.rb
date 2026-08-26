module MarketData
  module Gateways
    # Driven adapter: Yahoo Finance through the yfinance Python library.
    #
    # Yahoo's HTTP surface answers 429 to every request a Ruby client can make,
    # including from a residential connection — the block is on the TLS
    # fingerprint, so YahooFinanceGateway cannot reach it and this can. It
    # covers the three capabilities no sanctioned provider serves: index
    # levels, BMV dividends and BMV splits.
    #
    # It is deliberately rate limited well below anything Yahoo would notice.
    class YfinanceGateway < MarketDataGateway
      include Dry::Monads[:result]

      PROVIDER = "Yahoo Finance"
      SCRIPT = "yahoo.py".freeze
      PERIODS = { 7 => "5d", 30 => "1mo", 90 => "3mo", 365 => "1y" }.freeze
      INDEX_SYMBOL_MAP = YahooFinanceGateway::INDEX_SYMBOL_MAP

      def fetch_price(symbol)
        run("quote", symbol).fmap do |data|
          {
            symbol: symbol,
            price: data["price"].to_d,
            change_percent: data["change_percent"].to_d,
            volume: data["volume"]&.to_i,
            as_of: parse_time(data["as_of"])
          }
        end
      end

      # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
      def fetch_historical(symbol, days: 30)
        run("history", symbol, period_for(days)).fmap do |bars|
          bars.map do |bar|
            {
              date: Date.parse(bar["date"]),
              open: bar["open"].to_d,
              high: bar["high"].to_d,
              low: bar["low"].to_d,
              close: bar["close"].to_d,
              volume: bar["volume"]&.to_i
            }
          end
        end
      end

      # Returns Success([{ ex_date:, pay_date:, amount_per_share:, currency: }, ...])
      # Shape matches FmpGateway and AlpacaGateway, so all three are interchangeable.
      def fetch_dividends(symbol, currency: "MXN")
        run("dividends", symbol).fmap do |entries|
          entries.map do |entry|
            { ex_date: Date.parse(entry["date"]), pay_date: nil,
              amount_per_share: entry["amount"].to_d, currency: currency }
          end
        end
      end

      # Yahoo reports a split as a single ratio, so a 4:1 arrives as 4.0 and a
      # 1-for-20 reverse split as 0.05.
      # Returns Success([{ date:, numerator:, denominator: }, ...])
      def fetch_splits(symbol)
        run("splits", symbol).fmap do |entries|
          entries.filter_map do |entry|
            ratio = entry["ratio"].to_d
            next if ratio.zero?

            numerator, denominator = ratio >= 1 ? [ ratio.round, 1 ] : [ 1, (1 / ratio).round ]
            { date: Date.parse(entry["date"]), numerator: numerator, denominator: denominator }
          end
        end
      end

      # Index levels have no sanctioned source: Alpaca has none, Massive charges
      # for them, and DataBursatil's feed has been frozen since 2026-06-26.
      # Returns Success([{ symbol:, value:, change_percent:, is_open: }, ...])
      def fetch_index_quotes(symbols = INDEX_SYMBOL_MAP.keys)
        quotes = symbols.filter_map do |yahoo_symbol|
          result = fetch_price(yahoo_symbol)
          next unless result.success?

          quote = result.value!
          {
            symbol: INDEX_SYMBOL_MAP.fetch(yahoo_symbol, yahoo_symbol),
            value: quote[:price],
            change_percent: quote[:change_percent],
            is_open: yahoo_symbol == "^MXX" ? MarketHours.bmv_market_open? : MarketHours.us_market_open?
          }
        end

        return Failure([ :not_found, "No index quotes from #{PROVIDER}" ]) if quotes.empty?

        Success(quotes)
      end

      private

      def run(command, symbol, *extra)
        check = RateLimiter.check!(PROVIDER)
        return check if check.failure?

        PythonRunner.call(SCRIPT, command, symbol, *extra)
      end

      def period_for(days)
        PERIODS.find { |limit, _| days <= limit }&.last || "max"
      end

      def parse_time(value)
        value.present? ? Time.zone.parse(value) : nil
      rescue ArgumentError
        nil
      end
    end
  end
end
