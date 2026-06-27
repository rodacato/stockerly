module MarketData
  module Gateways
    # Driven adapter: Yahoo Finance API for BMV (Mexican) stock/ETF prices and market indices.
    # Uses the v8/finance/chart endpoint on query2 (the v8/finance/quote endpoint is deprecated).
    class YahooFinanceGateway < MarketDataGateway
    include Dry::Monads[:result]

    BASE_URL = "https://query2.finance.yahoo.com"
    RATE_LIMITED_MESSAGE = "Yahoo Finance rate limit exceeded"
    USER_AGENT_HEADER = "User-Agent"
    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    TIMEOUT  = 5

    # Yahoo Finance symbols → our internal MarketIndex symbols
    INDEX_SYMBOL_MAP = {
      "^GSPC" => "SPX",
      "^IXIC" => "NDX",
      "^DJI"  => "DJI",
      "^FTSE" => "UKX",
      "^MXX"  => "IPC",
      "^VIX"  => "VIX"
    }.freeze

    def initialize(api_key: nil)
      # Yahoo Finance v8 does not require an API key
    end

    # Fetch latest quote for a single symbol (e.g. "GENIUSSACV.MX").
    # Returns Success({ symbol:, price:, change_percent:, volume: })
    def fetch_price(symbol)
      result = fetch_chart(symbol)
      return result if result.failure?

      meta = result.value!
      Success({
        symbol: symbol,
        price: meta["regularMarketPrice"].to_d,
        change_percent: compute_change_percent(meta),
        volume: meta["regularMarketVolume"]&.to_i
      })
    end

    # Batch fetch quotes for multiple symbols in a single HTTP request.
    # Uses /v7/finance/quote endpoint. Falls back to individual chart calls on failure.
    # Returns Success([{ symbol:, price:, change_percent:, volume: }, ...])
    def fetch_batch_quotes(symbols)
      response = batch_connection.get("/v7/finance/quote") do |req|
        req.params["symbols"] = symbols.join(",")
      end

      return fallback_bulk_prices(symbols) if response.status == 429
      return fallback_bulk_prices(symbols) unless response.success?

      results = parse_batch_quotes(response.body)
      return fallback_bulk_prices(symbols) if results.empty?

      Success(results)
    rescue Faraday::Error
      fallback_bulk_prices(symbols)
    end

    # Fetch prices for multiple symbols (one chart call per symbol).
    # Returns Success([{ symbol:, price:, ... }, ...])
    def fetch_bulk_prices(symbols)
      fetch_batch_quotes(symbols)
    end

    # Fetch daily price history for a single symbol.
    # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
    def fetch_historical(symbol, days: 30)
      response = connection.get("/v8/finance/chart/#{ERB::Util.url_encode(symbol)}") do |req|
        req.params["range"] = "#{days}d"
        req.params["interval"] = "1d"
      end

      return Failure([ :rate_limited, RATE_LIMITED_MESSAGE ]) if response.status == 429
      return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

      parse_historical(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Search tickers by name or symbol via Yahoo Finance search API.
    # Returns Success([{ symbol:, name:, quote_type:, exchange:, exchange_display: }, ...])
    def search_tickers(query)
      response = search_connection.get("/v1/finance/search") do |req|
        req.params["q"] = query
        req.params["quotesCount"] = 8
        req.params["newsCount"] = 0
        req.params["enableFuzzyQuery"] = true
      end

      return Failure([ :rate_limited, RATE_LIMITED_MESSAGE ]) if response.status == 429
      return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

      quotes = response.body["quotes"] || []
      results = quotes.filter_map { |q| parse_search_result(q) }

      Success(results)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch the next earnings event for a ticker via Yahoo's quoteSummary
    # `calendarEvents` module. Used for BMV emisoras where Polygon/Finnhub
    # have no coverage. The endpoint returns the upcoming report only — Yahoo
    # does not expose a forward-looking calendar list per ticker — so the
    # Success array carries 0 or 1 element.
    #
    # When `earningsDate` is a single value the event is confirmed; when it's
    # a [low, high] range the date is unconfirmed and we take the upper bound
    # so the calendar isn't optimistic.
    #
    # Returns Success([{ report_date:, fiscal_quarter:, fiscal_year:,
    #                   estimated_eps:, actual_eps:, timing:, confirmed: }, ...])
    def fetch_earnings(ticker)
      response = connection.get("/v10/finance/quoteSummary/#{ERB::Util.url_encode(ticker)}") do |req|
        req.params["modules"] = "calendarEvents,earnings"
      end

      return Failure([ :rate_limited, RATE_LIMITED_MESSAGE ]) if response.status == 429
      return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

      parse_earnings(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch quotes for market indices (S&P 500, NASDAQ, DOW, FTSE, IPC, VIX).
    # Returns Success([{ symbol:, name:, value:, change_percent:, is_open: }, ...])
    def fetch_index_quotes(symbols = INDEX_SYMBOL_MAP.keys)
      quotes = []
      last_error = nil

      symbols.each do |yahoo_sym|
        result = fetch_chart(yahoo_sym)

        if result.failure?
          last_error = result
          next
        end

        meta = result.value!
        our_sym = INDEX_SYMBOL_MAP[yahoo_sym] || yahoo_sym

        quotes << {
          symbol: our_sym,
          name: meta["shortName"] || meta["longName"] || our_sym,
          value: meta["regularMarketPrice"].to_d,
          change_percent: compute_change_percent(meta),
          is_open: market_open?(meta)
        }
      end

      return last_error if quotes.empty? && last_error
      return Failure([ :not_found, "No index data returned" ]) if quotes.empty?

      Success(quotes)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    private

    def fetch_chart(symbol)
      response = connection.get("/v8/finance/chart/#{ERB::Util.url_encode(symbol)}") do |req|
        req.params["range"] = "1d"
        req.params["interval"] = "1d"
      end

      return Failure([ :rate_limited, RATE_LIMITED_MESSAGE ]) if response.status == 429
      return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

      meta = response.body.dig("chart", "result", 0, "meta")
      return Failure([ :not_found, "No data for #{symbol}" ]) unless meta

      Success(meta)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 3, interval: 1, backoff_factor: 2,
                          retry_statuses: [ 500, 502, 503 ]
        f.headers[USER_AGENT_HEADER] = USER_AGENT
        f.headers["Accept"] = "application/json"
        f.response :json
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    def compute_change_percent(meta)
      price = meta["regularMarketPrice"]&.to_d
      prev  = meta["chartPreviousClose"]&.to_d
      return BigDecimal("0") if prev.nil? || prev.zero?

      ((price - prev) / prev * 100).round(4)
    end

    def market_open?(meta)
      trading = meta.dig("currentTradingPeriod", "regular")
      return false unless trading

      now = Time.current.to_i
      now >= trading["start"].to_i && now <= trading["end"].to_i
    end

    # Dedicated connection for search — no retry middleware, no Accept: application/json.
    # Yahoo Finance blocks automated-looking search requests.
    def search_connection
      @search_connection ||= Faraday.new(url: BASE_URL) do |f|
        f.headers[USER_AGENT_HEADER] = USER_AGENT
        f.response :json
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    def batch_connection
      @batch_connection ||= Faraday.new(url: "https://query1.finance.yahoo.com") do |f|
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                          retry_statuses: [ 500, 502, 503 ]
        f.headers[USER_AGENT_HEADER] = USER_AGENT
        f.headers["Accept"] = "application/json"
        f.response :json
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    def parse_search_result(quote)
      return nil unless quote["symbol"].present?

      {
        symbol: quote["symbol"],
        name: quote["longname"] || quote["shortname"] || quote["symbol"],
        quote_type: quote["quoteType"],
        exchange: quote["exchange"],
        exchange_display: quote["exchDisp"]
      }
    end

    def parse_batch_quotes(body)
      results = body.dig("quoteResponse", "result") || []
      results.filter_map do |quote|
        symbol = quote["symbol"]
        price = quote["regularMarketPrice"]
        next unless symbol && price

        {
          symbol: symbol,
          price: price.to_d,
          change_percent: quote["regularMarketChangePercent"]&.round(4) || BigDecimal("0"),
          volume: quote["regularMarketVolume"]&.to_i
        }
      end
    end

    def fallback_bulk_prices(symbols)
      results = []
      last_error = nil

      symbols.each do |symbol|
        result = fetch_chart(symbol)

        if result.failure?
          last_error = result
          next
        end

        meta = result.value!
        results << {
          symbol: symbol,
          price: meta["regularMarketPrice"].to_d,
          change_percent: compute_change_percent(meta),
          volume: meta["regularMarketVolume"]&.to_i
        }
      end

      return last_error if results.empty? && last_error

      Success(results)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Yahoo's calendarEvents shape:
    #   quoteSummary.result[0].calendarEvents.earnings
    #     earningsDate: [{raw: <unix>, fmt: "YYYY-MM-DD"}]            -> confirmed
    #     earningsDate: [{raw: <low>}, {raw: <high>}]                 -> unconfirmed (range)
    #     earningsAverage / earningsLow / earningsHigh: EPS estimates
    #
    # The :timing field is left nil for BMV emisoras — Yahoo does not surface
    # before/after market open for `.MX` tickers, and SyncEarnings#upsert_event
    # defaults to :after_market_close when timing is absent.
    def parse_earnings(body)
      cal     = body.dig("quoteSummary", "result", 0, "calendarEvents", "earnings")
      summary = body.dig("quoteSummary", "result", 0, "earnings", "earningsChart")
      return Success([]) if cal.blank?

      dates = Array(cal["earningsDate"])
      return Success([]) if dates.empty?

      raws = dates.map { |d| d.is_a?(Hash) ? d["raw"] : d }.compact
      return Success([]) if raws.empty?

      report_date = Time.at(raws.max).utc.to_date
      confirmed   = raws.size == 1

      # Yahoo's calendarEvents only carries the UPCOMING earnings event, so
      # actual_eps is always nil here — Yahoo doesn't expose actuals on this
      # endpoint. earningsAverage is the primary estimate; earningsChart's
      # currentQuarterEstimate is a documented fallback when calendarEvents
      # omits the average.
      estimate  = cal.dig("earningsAverage", "raw")&.to_d
      estimate ||= summary&.dig("currentQuarterEstimate", "raw")&.to_d

      event = {
        report_date:    report_date,
        fiscal_quarter: ((report_date.month - 1) / 3) + 1,
        fiscal_year:    report_date.year,
        estimated_eps:  estimate,
        actual_eps:     nil,
        confirmed:      confirmed
      }

      Success([ event ])
    end

    def parse_historical(body)
      result = body.dig("chart", "result", 0)
      return Failure([ :not_found, "No chart data in Yahoo response" ]) unless result

      timestamps = result["timestamp"]
      indicators = result.dig("indicators", "quote", 0)
      return Failure([ :parse_error, "Missing OHLCV data" ]) if timestamps.blank? || indicators.blank?

      bars = timestamps.each_with_index.filter_map do |ts, i|
        close = indicators.dig("close", i)
        next unless close

        {
          date: Time.at(ts).to_date,
          open:   (indicators.dig("open", i) || close).to_d,
          high:   (indicators.dig("high", i) || close).to_d,
          low:    (indicators.dig("low", i)  || close).to_d,
          close:  close.to_d,
          volume: indicators.dig("volume", i)&.to_i
        }
      end

      bars.uniq! { |b| b[:date] }
      Success(bars)
    end
    end
  end
end
