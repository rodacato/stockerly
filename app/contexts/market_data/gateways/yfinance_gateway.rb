module MarketData
  module Gateways
    # Driven adapter: Yahoo Finance through the yfinance Python library.
    #
    # The only way in: a plain Ruby client is blocked on its TLS fingerprint,
    # and the endpoints that survive that still answer 401 without a session
    # crumb. yfinance handles both, which is why this is now the whole of
    # Yahoo Finance here — prices, history, index levels, BMV dividends,
    # BMV splits and BMV earnings.
    #
    # It is deliberately rate limited well below anything Yahoo would notice.
    class YfinanceGateway < MarketDataGateway
      include Dry::Monads[:result]

      PROVIDER = "Yahoo Finance"
      SCRIPT = "yahoo.py".freeze
      # Far enough back to catch the quarter that just reported -- and its
      # actual EPS -- without pouring six years of history into the table.
      HISTORY_WINDOW_DAYS = 180
      PERIODS = { 7 => "5d", 30 => "1mo", 90 => "3mo", 365 => "1y" }.freeze
      # Yahoo's own tickers on the left, the symbols MarketIndex stores on the right.
      INDEX_SYMBOL_MAP = {
        "^GSPC" => "SPX",
        "^IXIC" => "NDX",
        "^DJI"  => "DJI",
        "^FTSE" => "UKX",
        "^MXX"  => "IPC",
        "^VIX"  => "VIX"
      }.freeze

      def self.source_id
        "#{PROVIDER}/yfinance"
      end

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

      # Yahoo's quoteSummary endpoint answers 401 without a session crumb, which
      # is what left BMV earnings unsynced; yfinance carries the crumb itself.
      # Returns Success([{ report_date:, timing:, estimated_eps:, actual_eps: }, ...])
      def fetch_earnings(symbol)
        floor = Date.current - HISTORY_WINDOW_DAYS
        run("earnings", symbol).fmap do |entries|
          entries.filter_map do |entry|
            date = Date.parse(entry["date"])
            next if date < floor

            { report_date: date, timing: timing_for(entry["hour"]),
              estimated_eps: entry["estimated_eps"]&.to_d, actual_eps: entry["actual_eps"]&.to_d }
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

      # Matching nothing is Success([]), not a failure: "no such ticker" and
      # "the provider is down" have to stay distinguishable upstream.
      def search_tickers(query)
        run("search", query).fmap do |matches|
          matches.map do |match|
            {
              symbol: match["symbol"],
              name: match["name"],
              quote_type: match["quote_type"],
              exchange: match["exchange"],
              sector: match["sector"]
            }
          end
        end
      end

      private

      def run(command, symbol, *extra)
        check = RateLimiter.check!(PROVIDER)
        return check if check.failure?

        PythonRunner.call(SCRIPT, command, symbol, *extra)
      end

      # The hour Yahoo publishes is the only signal separating a pre-open report
      # from a post-close one, and it arrives in the exchange's own timezone.
      def timing_for(hour)
        hour.to_i < 12 ? :before_market_open : :after_market_close
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
