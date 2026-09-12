module MarketData
  module Gateways
    # Driven adapter: DataBursatil for BMV and BIVA quotes, end-of-day series
    # and intraday bars. Docs: https://databursatil.com/docs.html
    #
    # Quota is metered in transmitted bytes rather than requests — one credit
    # per KiB, rounded up, out of 200,000 a month — so `concepto` asks for the
    # narrowest set of fields each caller needs. The remaining balance is read
    # from the provider instead of counted locally, and cached, because asking
    # for it also costs a credit.
    class DataBursatilGateway < MarketDataGateway
      include PerformsRequests
      include ResolvesApiKey
      include Dry::Monads[:result]

      BASE_URL = "https://api.databursatil.com"
      PROVIDER = "DataBursatil"
      DEFAULT_EXCHANGE = "BMV"
      QUOTE_FIELDS = "u,c,v,f".freeze
      CREDITS_CACHE_KEY = "databursatil:credits".freeze
      CREDITS_TTL = 1.hour
      MONTHLY_CREDITS = 200_000

      # The one provider that reports its own balance. A nil balance draws no
      # bar rather than a zero: unknown and unused are different readings.
      def self.quota(_integration)
        remaining = new.remaining_credits
        MarketData::Domain::SourceCatalogue::Quota.new(
          used: remaining ? MONTHLY_CREDITS - remaining : 0,
          limit: remaining ? MONTHLY_CREDITS : nil,
          unit: :kib_per_month
        )
      rescue ApiKeyNotConfiguredError
        MarketData::Domain::SourceCatalogue::Quota.new(used: 0, limit: nil, unit: :kib_per_month)
      end
      TIMEOUT = 8

      def initialize(api_key: nil)
        @token = api_key || resolve_api_key
      end

      def self.source_id(exchange = DEFAULT_EXCHANGE)
        "#{PROVIDER}/#{exchange.downcase}"
      end

      def source_id(exchange = DEFAULT_EXCHANGE)
        self.class.source_id(exchange)
      end

      # Returns Success({ symbol:, price:, volume:, as_of: })
      def fetch_price(symbol)
        result = fetch_bulk_prices([ symbol ])
        return result if result.failure?

        quote = result.value!.first
        return Failure([ :not_found, "No #{PROVIDER} quote for #{symbol}" ]) if quote.nil?

        Success(quote)
      end

      # One call covers many issuers, which is the whole reason this provider
      # replaces per-symbol polling.
      # Returns Success([{ symbol:, price:, volume:, as_of: }, ...])
      def fetch_bulk_prices(symbols, exchange: DEFAULT_EXCHANGE)
        requested = Array(symbols)
        result = get("/v2/cotizaciones", {
          concepto: QUOTE_FIELDS,
          emisora_serie: requested.map { |symbol| bmv_symbol(symbol) }.join(","),
          bolsa: exchange
        })
        return result if result.failure?

        quotes = requested.filter_map { |symbol| parse_quote(symbol, result.value!, exchange) }
        return Failure([ :not_found, "No #{PROVIDER} quotes for #{requested.size} symbols" ]) if quotes.empty?

        Success(quotes)
      end

      # The issuer catalogue, filtered. `letra` takes a whole ticker (the docs'
      # own example is `letra=NFLX`) and `mercado` narrows to the local market,
      # which is what makes this ~6 credits instead of the 2,181 an unfiltered
      # fetch costs (#379).
      #
      # Returns the body as the provider sent it, deliberately unparsed: the
      # row's shape has never been seen from this repo, and a parser written
      # against a guess would be worse than none. The first caller to run this
      # with a token is what settles the shape.
      # Returns Success(Hash | Array)
      def fetch_issuers(query, market: "local")
        return Failure([ :invalid_request, "An issuer query is required" ]) if query.blank?

        get("/v2/emisoras", { letra: query.to_s.upcase.delete_suffix(".MX"), mercado: market })
      end

      # The IPC's own feed froze at 2026-06-26, so the index is read through
      # NAFTRAC, the ETF that tracks it. Only the day's percentage crosses over:
      # an ETF price in pesos is not an index level, so `value` stays nil rather
      # than asserting the IPC is worth sixty-odd pesos. Nothing renders the
      # level; `_market_context` renders the name and the percentage.
      INDEX_PROXIES = { "IPC" => "NAFTRACISHRS" }.freeze

      # Returns Success([{ symbol:, value:, change_percent:, is_open: }, ...])
      # — the same shape the bridge returns, so the job routes by market rather
      # than chaining (ADR-021: an index with two providers could drift between
      # syncs, which is the defect that ADR closed for assets).
      def fetch_index_quotes(symbols = INDEX_PROXIES.keys)
        wanted = Array(symbols).map(&:to_s) & INDEX_PROXIES.keys
        return Failure([ :not_supported, "#{PROVIDER} proxies no index in #{Array(symbols).join(", ")}" ]) if wanted.empty?

        result = get("/v2/cotizaciones", {
          concepto: QUOTE_FIELDS,
          emisora_serie: wanted.map { |index| INDEX_PROXIES.fetch(index) }.join(","),
          bolsa: DEFAULT_EXCHANGE
        })
        return result if result.failure?

        quotes = wanted.filter_map { |index| parse_index_quote(index, result.value!) }
        return Failure([ :not_found, "No #{PROVIDER} index proxy quotes" ]) if quotes.empty?

        Success(quotes)
      end

      # End-of-day closes. This provider serves close and traded amount only —
      # there is no daily candle to be had, so open/high/low stay nil.
      # Returns Success([{ date:, close:, amount: }, ...])
      def fetch_historical(symbol, from_date = 30.days.ago.to_date, to_date = Date.current)
        result = get("/v2/historicos", {
          emisora_serie: bmv_symbol(symbol), inicio: from_date.to_s, final: to_date.to_s
        })
        return result if result.failure?

        bars = result.value!.filter_map do |date, values|
          close, amount = values
          next if close.blank?

          { date: Date.parse(date), close: close.to_d, amount: amount&.to_d }
        rescue Date::Error
          next
        end

        return Failure([ :not_found, "No #{PROVIDER} history for #{symbol}" ]) if bars.empty?

        Success(bars.sort_by { |bar| bar[:date] })
      end

      # Intraday bars from a sanctioned source, which is what the BMV side of a
      # provisional series needs.
      # Returns Success([{ at:, price: }, ...])
      def fetch_intraday(symbol, date: Date.current, interval: "5m", exchange: DEFAULT_EXCHANGE)
        key = bmv_symbol(symbol)
        result = get("/v2/intradia", {
          emisora_serie: key, bolsa: exchange, inicio: date.to_s, final: date.to_s, intervalo: interval
        })
        return result if result.failure?

        series = result.value![key] || {}
        return Failure([ :not_found, "No #{PROVIDER} intraday for #{symbol} on #{date}" ]) if series.empty?

        Success(series.map { |at, price| { at: Time.zone.parse(at), price: price.to_d } }.sort_by { |bar| bar[:at] })
      end

      # Credits remaining this month, straight from the provider. Cached because
      # the question itself costs one.
      def remaining_credits(force: false)
        Rails.cache.delete(CREDITS_CACHE_KEY) if force

        Rails.cache.fetch(CREDITS_CACHE_KEY, expires_in: CREDITS_TTL) do
          result = get("/v2/creditos", {})
          result.success? ? result.value!["disponibles"]&.to_i : nil
        end
      end

      private

      # The BMV addresses an instrument by issuer and serie (WALMEX*), which is
      # mandatory: WALMEX alone is rejected outright, and one unknown name fails
      # the whole batch. Assets carry the mapping in provider_symbols; stripping
      # Yahoo's suffix is only the fallback for tickers that already embed it.
      def bmv_symbol(symbol)
        symbol.to_s.upcase.delete_suffix(".MX")
      end

      def parse_quote(symbol, body, exchange)
        venue = body[bmv_symbol(symbol)]&.dig(exchange.downcase)
        return if venue.nil? || venue["u"].blank?

        {
          symbol: symbol,
          source: source_id(exchange),
          price: venue["u"].to_d,
          volume: venue["v"]&.to_i,
          as_of: venue["f"].present? ? Time.zone.parse(venue["f"]) : nil
        }
      end

      def parse_index_quote(index_symbol, body)
        venue = body[INDEX_PROXIES.fetch(index_symbol)]&.dig(DEFAULT_EXCHANGE.downcase)
        return if venue.nil? || venue["c"].blank?

        {
          symbol: index_symbol,
          value: nil,
          change_percent: venue["c"].to_d,
          is_open: MarketHours.bmv_market_open?
        }
      end

      # Only the token, now that the budget is asked in get_json for every
      # gateway. This method is what said the request was the right place first.
      def get(path, params)
        get_json(path, params.merge(token: @token))
      end

      # Errors arrive as a map keyed by the parameter at fault, which says more
      # than the status alone: this provider answers 400 for both a bad
      # credential and a malformed query. The status mapping is the floor.
      def failure_from(response)
        errors = response.body.is_a?(Hash) ? response.body["Error"] : nil
        return GatewayFailure.from(response, PROVIDER) if errors.blank?

        return Failure([ :unauthorized, "#{PROVIDER}: #{Array(errors['token']).first}" ]) if errors.is_a?(Hash) && errors["token"].present?

        detail = errors.is_a?(Hash) ? errors.keys.join(", ") : errors
        Failure([ :invalid_request, "#{PROVIDER}: #{detail}" ])
      end

      def connection
        build_connection(url: BASE_URL, timeout: TIMEOUT, retry_options: { max: 2, interval: 0.5, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] })
      end
    end
  end
end
