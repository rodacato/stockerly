module MarketData
  module Gateways
    # Driven adapter: Banxico SIE API for CETES auction results.
    # Docs: https://www.banxico.org.mx/SieAPIRest/service/v1/doc/catalogoSeries
    class BanxicoGateway
    include PerformsRequests
    include ResolvesApiKey
    include Dry::Monads[:result]

    BASE_URL = "https://www.banxico.org.mx/SieAPIRest/service/v1/"
    PROVIDER = "Banxico"
    TIMEOUT  = 10

    # The FIX in its settlement series, not determination (SF43718): a broker
    # settles two banking days later, and this one has a row for every date.
    FIX_SERIES = "SF60653"
    FIX_SOURCE_ID = "Banxico/#{FIX_SERIES}".freeze
    FIX_SERIES_START = Date.new(1991, 11, 14)
    FIX_PAIR   = { base: "USD", quote: "MXN" }.freeze

    # Banxico series IDs for CETES by term (days)
    CETES_SERIES = {
      "28"  => "SF43936",
      "91"  => "SF43939",
      "182" => "SF43942",
      "364" => "SF43945"
    }.freeze

    # A floor to ask from, not a documented series start. Banxico answers with
    # whatever the series actually holds, so the first deep run is what reveals
    # where each term begins — the same way Alpaca's 2016 floor was found.
    CETES_HISTORY_FLOOR = Date.new(1980, 1, 1)

    # The terms that can be fetched at all: a term with no series id cannot.
    CETES_TERMS = CETES_SERIES.keys.freeze

    def self.cetes_terms = CETES_TERMS

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

      result = get_json("series/#{FIX_SERIES}/datos/#{format_date(from)}/#{format_date(to)}")
      return result if result.failure?

      parse_fixes(result.value!)
    end

    # Auction results for a term across a date range, oldest first. Same shape
    # as fetch_auctions — parse_auctions already walks the whole `datos` array,
    # so only the path differs. Reinvesting at 28 days across a year is roughly
    # 13 different rates, and `datos/oportuno` only ever returns the last one.
    def fetch_auction_series(term: "28", from: Date.current, to: Date.current)
      auctions_for(term, "#{format_date(from)}/#{format_date(to)}")
    end

    # The whole curve in one request. Banxico allows twenty series per call and
    # blocks an abusing token for a full calendar day — and this token serves FX
    # as well, so four calls where one suffices is the least affordable waste in
    # the stack.
    # Returns Success([{ term:, yield_rate:, price:, auction_date: }, ...])
    def fetch_all_terms
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("series/#{CETES_SERIES.values.join(',')}/datos/oportuno")
      return result if result.failure?

      parse_curve(result.value!)
    end

    private

    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT, retry_options: { max: 2, interval: 0.5, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] }) do |f|
        f.headers["Bmx-Token"] = @api_token
      end
    end

    # Both auction endpoints differ only in the path segment after `datos`:
    # `oportuno` for the latest, a date range for the series.
    def auctions_for(term, path_segment)
      series_id = CETES_SERIES[term.to_s]
      return Failure([ :not_found, "Unknown CETES term: #{term}" ]) unless series_id

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("series/#{series_id}/datos/#{path_segment}")
      return result if result.failure?

      parse_auctions(result.value!, term.to_s)
    end

    def parse_auctions(body, term)
      series = body.dig("bmx", "series", 0)
      return Failure([ :not_found, "No series data for CETES #{term}D" ]) unless series

      auctions = auctions_from(series["datos"], term)

      auctions.any? ? Success(auctions) : Failure([ :not_found, "No valid auction data for CETES #{term}D" ])
    end

    # Banxico answers a multi-series request in its own order, not the one asked
    # for, so each block is matched by idSerie. Reading them positionally would
    # mislabel every term and never say so.
    def parse_curve(body)
      terms_by_series = CETES_SERIES.invert

      auctions = Array(body.dig("bmx", "series")).flat_map do |series|
        term = terms_by_series[series["idSerie"]]
        term ? auctions_from(series["datos"], term) : []
      end

      auctions.any? ? Success(auctions) : Failure([ :not_found, "No CETES data available" ])
    end

    def auctions_from(datos, term)
      Array(datos).filter_map do |dato|
        yield_rate = dato["dato"]&.delete(",")&.to_f
        next unless yield_rate&.positive?

        {
          term: term,
          yield_rate: yield_rate,
          price: calculate_discount_price(10.0, yield_rate, term.to_i),
          auction_date: parse_date(dato["fecha"])
        }
      end
    end

    # The FIX for a given day does not exist before it is determined, from
    # 12:00 CDMX. That is a normal daily condition and was indistinguishable
    # from an outage while both returned :not_found.
    def parse_fixes(body)
      datos = body.dig("bmx", "series", 0, "datos")
      return empty_fixes_failure if datos.blank?

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
      (face_value / (1 + (annual_yield / 100.0 * days / 360.0))).round(6)
    end

    def empty_fixes_failure
      return Failure([ :not_yet_published, "#{PROVIDER}: the FIX is determined from 12:00 CDMX" ]) if before_fix_publication?

      Failure([ :not_found, "No FIX data for USD/MXN" ])
    end

    def before_fix_publication?
      Time.current.in_time_zone("America/Mexico_City").hour < 12
    end

    def parse_date(fecha_str)
      Date.strptime(fecha_str, "%d/%m/%Y")
    rescue Date::Error
      Date.current
    end
    end
  end
end
