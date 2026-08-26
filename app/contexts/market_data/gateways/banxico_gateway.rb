module MarketData
  module Gateways
    # Driven adapter: Banxico SIE API for CETES auction results.
    # Docs: https://www.banxico.org.mx/SieAPIRest/service/v1/doc/catalogoSeries
    class BanxicoGateway
    include Dry::Monads[:result]

    BASE_URL = "https://www.banxico.org.mx/SieAPIRest/service/v1/"
    PROVIDER = "Banxico"
    TIMEOUT  = 10

    # The official FIX — the rate Banxico publishes each business day and the one
    # a Mexican broker settles against (#177). SF43718 is its SIE series id;
    # the issue calls it TC_TC002, which is the portal's table, not the series.
    FIX_SERIES = "SF43718"
    FIX_PAIR   = { base: "USD", quote: "MXN" }.freeze

    # Banxico series IDs for CETES by term (days)
    CETES_SERIES = {
      "28"  => "SF43936",
      "91"  => "SF43939",
      "182" => "SF43942",
      "364" => "SF43945"
    }.freeze

    def initialize(api_key: nil)
      @api_token = api_key || resolve_api_key
    end

    # Fetch latest auction result for a specific CETES term.
    # Returns Success([{ term:, yield_rate:, price:, auction_date: }])
    def fetch_auctions(term: "28")
      auctions_for(term, "oportuno")
    end

    # The USD/MXN FIX for a date range, oldest first.
    # Returns Success([{ date:, rate: }, ...]) — a range so history can be
    # backfilled in one call instead of one request per day (ADR-009).
    def fetch_fx_fixes(from: Date.current, to: Date.current)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      path = "series/#{FIX_SERIES}/datos/#{format_date(from)}/#{format_date(to)}"
      response = connection.get(path)

      return Failure([ :rate_limited, "Banxico rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Banxico returned #{response.status}" ]) unless response.success?

      parse_fixes(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Auction results for a term across a date range, oldest first. Same shape
    # as fetch_auctions — parse_auctions already walks the whole `datos` array,
    # so only the path differs. Reinvesting at 28 days across a year is roughly
    # 13 different rates, and `datos/oportuno` only ever returns the last one.
    def fetch_auction_series(term: "28", from: Date.current, to: Date.current)
      auctions_for(term, "#{format_date(from)}/#{format_date(to)}")
    end

    # Fetch latest auctions for all CETES terms.
    # Returns Success([{ term:, yield_rate:, price:, auction_date: }, ...])
    def fetch_all_terms
      results = []

      CETES_SERIES.each_key do |term|
        result = fetch_auctions(term: term)
        results.concat(result.value!) if result.success?
      end

      results.any? ? Success(results) : Failure([ :not_found, "No CETES data available" ])
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    private

    def resolve_api_key
      key = ApiKeyResolver.for(PROVIDER)
      raise ApiKeyNotConfiguredError.new(PROVIDER) if key.blank?
      key
    rescue ActiveRecord::Encryption::Errors::Decryption
      raise ApiKeyNotConfiguredError.new(PROVIDER, reason: "decryption failed")
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                          retry_statuses: [ 500, 502, 503 ]
        f.response :json
        f.headers["Bmx-Token"] = @api_token
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    # Both auction endpoints differ only in the path segment after `datos`:
    # `oportuno` for the latest, a date range for the series.
    def auctions_for(term, path_segment)
      series_id = CETES_SERIES[term.to_s]
      return Failure([ :not_found, "Unknown CETES term: #{term}" ]) unless series_id

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("series/#{series_id}/datos/#{path_segment}")

      return Failure([ :rate_limited, "Banxico rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Banxico returned #{response.status}" ]) unless response.success?

      parse_auctions(response.body, term.to_s)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    def parse_auctions(body, term)
      series = body.dig("bmx", "series", 0)
      return Failure([ :not_found, "No series data for CETES #{term}D" ]) unless series

      datos = series["datos"]
      return Failure([ :not_found, "No auction data for CETES #{term}D" ]) if datos.blank?

      auctions = datos.filter_map do |dato|
        yield_rate = dato["dato"]&.gsub(",", "")&.to_f
        next unless yield_rate && yield_rate > 0

        {
          term: term,
          yield_rate: yield_rate,
          price: calculate_discount_price(10.0, yield_rate, term.to_i),
          auction_date: parse_date(dato["fecha"])
        }
      end

      auctions.any? ? Success(auctions) : Failure([ :not_found, "No valid auction data for CETES #{term}D" ])
    end

    def parse_fixes(body)
      datos = body.dig("bmx", "series", 0, "datos")
      return Failure([ :not_found, "No FIX data for USD/MXN" ]) if datos.blank?

      # Banxico marks non-publication days as "N/E"; they are holidays, not errors.
      fixes = datos.filter_map do |dato|
        rate = dato["dato"].to_s.delete(",").to_f
        next unless rate.positive?

        { date: parse_date(dato["fecha"]), rate: rate }
      end

      fixes.any? ? Success(fixes.sort_by { |f| f[:date] }) : Failure([ :not_found, "No valid FIX data for USD/MXN" ])
    end

    def format_date(date)
      date.strftime("%Y-%m-%d")
    end

    def calculate_discount_price(face_value, annual_yield, days)
      (face_value / (1 + annual_yield / 100.0 * days / 360.0)).round(6)
    end

    def parse_date(fecha_str)
      Date.strptime(fecha_str, "%d/%m/%Y")
    rescue Date::Error
      Date.current
    end
    end
  end
end
