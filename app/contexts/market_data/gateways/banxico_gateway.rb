module MarketData
  module Gateways
    # Driven adapter: Banxico SIE API for CETES auction results.
    # Docs: https://www.banxico.org.mx/SieAPIRest/service/v1/doc/catalogoSeries
    class BanxicoGateway
    include Dry::Monads[:result]

    BASE_URL = "https://www.banxico.org.mx/SieAPIRest/service/v1/"
    TIMEOUT  = 10

    # Banxico series IDs for CETES by term (days)
    CETES_SERIES = {
      "28"  => "SF43936",
      "91"  => "SF43939",
      "182" => "SF43942",
      "364" => "SF43945"
    }.freeze

    def initialize(api_token: nil)
      @api_token = api_token || ENV.fetch("BANXICO_API_TOKEN", "")
    end

    # Fetch latest auction result for a specific CETES term.
    # Returns Success([{ term:, yield_rate:, price:, auction_date: }])
    def fetch_auctions(term: "28")
      series_id = CETES_SERIES[term.to_s]
      return Failure([ :not_found, "Unknown CETES term: #{term}" ]) unless series_id

      response = connection.get("series/#{series_id}/datos/oportuno")

      return Failure([ :rate_limited, "Banxico rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Banxico returned #{response.status}" ]) unless response.success?

      parse_auctions(response.body, term.to_s)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
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
