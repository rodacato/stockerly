module MarketData
  module Gateways
    # Driven adapter: Alpaca Market Data API for confirmed US daily bars,
    # corporate actions and news. Docs: https://docs.alpaca.markets/us/reference
    #
    # A Basic key serves the SIP consolidated tape for anything older than 15
    # minutes and returns 403 for anything newer, so this gateway covers
    # end-of-day history and never current prices.
    class AlpacaGateway < MarketDataGateway
      include Dry::Monads[:result]

      BASE_URL = "https://data.alpaca.markets"
      PROVIDER = "Alpaca"
      RATE_LIMITED_MESSAGE = "#{PROVIDER} rate limit exceeded"
      RECENCY_WALL = 15.minutes
      MAX_PAGES = 20
      TIMEOUT = 8

      # Alpaca authenticates with a key id and a secret, so the single stored
      # credential holds both as "KEY_ID:SECRET".
      def initialize(api_key: nil)
        @key_id, @secret = (api_key || resolve_api_key).split(":", 2)
        raise ApiKeyNotConfiguredError.new(PROVIDER, reason: "expected KEY_ID:SECRET") if @secret.blank?
      end

      def fetch_price(_symbol)
        Failure([ :no_entitlement, "#{PROVIDER} Basic cannot serve current prices; anything under 15 minutes is denied" ])
      end

      # Daily bars for several symbols in one paginated call.
      # Returns Success({ "AAPL" => [{ date:, open:, high:, low:, close:, volume: }, ...] })
      def fetch_daily_bars(symbols, from_date, to_date)
        check = RateLimiter.check!(PROVIDER)
        return check if check.failure?

        collected = Hash.new { |hash, key| hash[key] = [] }
        page_token = nil

        MAX_PAGES.times do
          response = get("/v2/stocks/bars", {
            symbols: Array(symbols).join(","),
            timeframe: "1Day",
            start: from_date.to_s,
            end: clamp_to_wall(to_date),
            feed: "sip",
            adjustment: "all",
            limit: 10_000,
            page_token: page_token
          }.compact)

          return response if response.failure?

          body = response.value!
          (body["bars"] || {}).each { |symbol, bars| collected[symbol].concat(bars.map { |bar| parse_bar(bar) }) }

          page_token = body["next_page_token"]
          break if page_token.blank?
        end

        Success(collected)
      end

      # Chain-compatible signature; delegates to the batch endpoint. The
      # defaults also make it usable as a one-argument connectivity test.
      # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
      def fetch_historical(symbol, from_date = 7.days.ago.to_date, to_date = Date.current)
        result = fetch_daily_bars([ symbol ], from_date, to_date)
        return result if result.failure?

        bars = result.value![symbol]
        return Failure([ :not_found, "No historical data for #{symbol}" ]) if bars.blank?

        Success(bars)
      end

      # Latest confirmed close per symbol, in the shape PolygonGateway's
      # grouped-daily endpoint returned, so the bulk job reads it unchanged.
      # Returns Success([{ symbol:, price:, change_percent:, volume: }, ...])
      def fetch_bulk_prices(symbols)
        result = fetch_daily_bars(symbols, 7.days.ago.to_date, Time.current)
        return result if result.failure?

        prices = result.value!.filter_map do |symbol, bars|
          bar = bars.max_by { |b| b[:date] }
          next if bar.nil?

          {
            symbol: symbol,
            price: bar[:close],
            change_percent: change_percent(bar[:open], bar[:close]),
            volume: bar[:volume]
          }
        end

        return Failure([ :not_found, "No confirmed closes for #{Array(symbols).size} symbols" ]) if prices.empty?

        Success(prices)
      end

      # Returns Success([{ ex_date:, pay_date:, amount_per_share:, currency: }, ...])
      # Shape matches FmpGateway#fetch_dividends so the two are interchangeable.
      def fetch_dividends(symbol, from_date: 5.years.ago.to_date, to_date: Date.current)
        result = corporate_actions(symbol, "cash_dividend", from_date, to_date)
        return result if result.failure?

        dividends = Array(result.value!["cash_dividends"]).filter_map do |entry|
          next if entry["ex_date"].blank? || entry["rate"].blank?

          {
            ex_date: Date.parse(entry["ex_date"]),
            pay_date: entry["payable_date"].present? ? Date.parse(entry["payable_date"]) : nil,
            amount_per_share: entry["rate"].to_d,
            currency: "USD"
          }
        rescue Date::Error
          next
        end

        Success(dividends)
      end

      # Returns Success([{ title:, summary:, source:, url:, image_url:, published_at:, related_ticker: }, ...])
      def fetch_news(ticker: nil, limit: 20)
        check = RateLimiter.check!(PROVIDER)
        return check if check.failure?

        params = { limit: limit.clamp(1, 50), sort: "desc" }
        params[:symbols] = ticker if ticker.present?

        response = get("/v1beta1/news", params)
        return response if response.failure?

        parse_news(response.value!, ticker)
      end

      private

      def corporate_actions(symbol, types, from_date, to_date)
        check = RateLimiter.check!(PROVIDER)
        return check if check.failure?

        get("/v1/corporate-actions", {
          symbols: symbol, types: types, start: from_date.to_s, end: to_date.to_s, limit: 1000
        }).fmap { |body| body["corporate_actions"] || {} }
      end

      # Requesting inside the 15-minute wall is a 403 for a Basic key, so the
      # upper bound is pulled back instead of being sent as asked.
      def clamp_to_wall(to_date)
        requested = to_date.respond_to?(:to_time) ? to_date.to_time : Time.zone.parse(to_date.to_s)
        wall = RECENCY_WALL.ago
        (requested && requested < wall ? requested : wall).utc.iso8601
      end

      def get(path, params)
        response = connection.get(path) { |req| req.params.update(params.transform_keys(&:to_s)) }

        return Failure([ :rate_limited, RATE_LIMITED_MESSAGE ]) if response.status == 429
        return Failure([ :no_entitlement, entitlement_message(response) ]) if response.status == 403
        return Failure([ :gateway_error, "#{PROVIDER} returned #{response.status}" ]) unless response.success?

        Success(response.body)
      rescue Faraday::Error => e
        Failure([ :gateway_error, e.message ])
      end

      def entitlement_message(response)
        detail = response.body.is_a?(Hash) ? response.body["message"] : nil
        "#{PROVIDER}: #{detail.presence || 'not permitted on this subscription'}"
      end

      def connection
        @connection ||= Faraday.new(url: BASE_URL) do |f|
          f.request :retry, max: 2, interval: 0.5, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ]
          f.response :json
          f.headers["APCA-API-KEY-ID"] = @key_id
          f.headers["APCA-API-SECRET-KEY"] = @secret
          f.options.timeout = TIMEOUT
          f.options.open_timeout = TIMEOUT
        end
      end

      def change_percent(open, close)
        return BigDecimal("0") if open.nil? || open.zero?

        ((close - open) / open * 100).round(2)
      end

      def parse_bar(bar)
        {
          date: Time.parse(bar["t"]).to_date,
          open: bar["o"].to_d,
          high: bar["h"].to_d,
          low: bar["l"].to_d,
          close: bar["c"].to_d,
          volume: bar["v"]&.to_i
        }
      end

      def parse_news(body, ticker)
        articles = Array(body["news"]).filter_map do |item|
          next if item["headline"].blank?

          {
            title: item["headline"],
            summary: item["summary"],
            source: item["source"].presence || PROVIDER,
            url: item["url"],
            image_url: item["images"]&.first&.dig("url"),
            published_at: item["created_at"].present? ? Time.parse(item["created_at"]) : nil,
            related_ticker: ticker.presence || item["symbols"]&.first
          }
        end

        Success(articles)
      end

      def resolve_api_key
        key = ApiKeyResolver.for(PROVIDER)
        raise ApiKeyNotConfiguredError.new(PROVIDER) if key.blank?
        key
      rescue ActiveRecord::Encryption::Errors::Decryption
        raise ApiKeyNotConfiguredError.new(PROVIDER, reason: "decryption failed")
      end
    end
  end
end
