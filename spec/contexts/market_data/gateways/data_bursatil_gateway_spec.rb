require "rails_helper"

RSpec.describe MarketData::Gateways::DataBursatilGateway do
  subject(:gateway) { described_class.new(api_key: "test-token") }

  before { Rails.cache.clear }

  describe "#fetch_bulk_prices" do
    it "returns one quote per requested symbol, keyed back to our symbol" do
      stub_databursatil("/v2/cotizaciones", {
        "WALMEX" => { "bmv" => databursatil_quote(last: 68.10) },
        "GFNORTEO" => { "bmv" => databursatil_quote(last: 193.64, change: 1.77) }
      })

      result = gateway.fetch_bulk_prices(%w[WALMEX.MX GFNORTEO.MX])

      expect(result.value!).to eq([
        { symbol: "WALMEX.MX", source: "DataBursatil/bmv", price: BigDecimal("68.1"),
          volume: 1_222_566, as_of: Time.zone.parse("2026-08-26 10:03:00") },
        { symbol: "GFNORTEO.MX", source: "DataBursatil/bmv", price: BigDecimal("193.64"),
          volume: 1_222_566, as_of: Time.zone.parse("2026-08-26 10:03:00") }
      ])
    end

    it "asks for one exchange and only the fields it needs" do
      stub_databursatil("/v2/cotizaciones", { "WALMEX" => { "bmv" => databursatil_quote(last: 68.10) } })

      gateway.fetch_bulk_prices(%w[WALMEX.MX])

      expect(
        a_request(:get, %r{api\.databursatil\.com/v2/cotizaciones})
          .with(query: hash_including("concepto" => "u,c,v,f", "bolsa" => "BMV", "emisora_serie" => "WALMEX"))
      ).to have_been_made
    end

    # The same issuer trades on both venues at different prices and times, so
    # asking for one venue is what keeps a quote unambiguous.
    # Provenance has to name the venue, not just the vendor: the two disagree.
    it "records which venue produced the quote" do
      stub_databursatil("/v2/cotizaciones", {
        "AMXB" => { "biva" => databursatil_quote(last: 20.31) }
      })

      quote = gateway.fetch_bulk_prices(%w[AMXB.MX], exchange: "BIVA").value!.first

      expect(quote[:source]).to eq("DataBursatil/biva")
    end

    it "reads the requested venue and ignores the other" do
      stub_databursatil("/v2/cotizaciones", {
        "AMXB" => { "bmv" => databursatil_quote(last: 20.27), "biva" => databursatil_quote(last: 20.31) }
      })

      expect(gateway.fetch_bulk_prices(%w[AMXB.MX]).value!.first[:price]).to eq(BigDecimal("20.27"))
    end

    it "reports symbols the provider does not know as not found" do
      stub_databursatil("/v2/cotizaciones", {})

      result = gateway.fetch_bulk_prices(%w[NOSUCH.MX])

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end
  end

  describe "#fetch_price" do
    it "returns the single quote" do
      stub_databursatil("/v2/cotizaciones", { "WALMEX" => { "bmv" => databursatil_quote(last: 68.10) } })

      expect(gateway.fetch_price("WALMEX.MX").value![:price]).to eq(BigDecimal("68.1"))
    end
  end

  describe "#fetch_historical" do
    it "returns closes in date order, with no candle it cannot supply" do
      stub_databursatil("/v2/historicos", {
        "2026-07-02" => [ 187.7, 1_333_070_159.75 ],
        "2026-07-01" => [ 189.77, 919_706_180.97 ]
      })

      bars = gateway.fetch_historical("GFNORTEO.MX", Date.new(2026, 7, 1), Date.new(2026, 7, 2)).value!

      expect(bars).to eq([
        { date: Date.new(2026, 7, 1), close: BigDecimal("189.77"), amount: BigDecimal("919706180.97") },
        { date: Date.new(2026, 7, 2), close: BigDecimal("187.7"), amount: BigDecimal("1333070159.75") }
      ])
    end

    it "reports an empty series as not found" do
      stub_databursatil("/v2/historicos", {})

      expect(gateway.fetch_historical("NOSUCH.MX").failure[0]).to eq(:not_found)
    end
  end

  describe "#fetch_intraday" do
    it "returns the series in time order" do
      stub_databursatil("/v2/intradia", {
        "GFNORTEO" => { "2026-08-25 07:40:00" => 187.5, "2026-08-25 07:35:00" => 186.75 }
      })

      bars = gateway.fetch_intraday("GFNORTEO.MX", date: Date.new(2026, 8, 25)).value!

      expect(bars.map { |bar| bar[:price] }).to eq([ BigDecimal("186.75"), BigDecimal("187.5") ])
    end

    it "passes the interval the caller asked for" do
      stub_databursatil("/v2/intradia", { "GFNORTEO" => { "2026-08-25 07:35:00" => 186.75 } })

      gateway.fetch_intraday("GFNORTEO.MX", date: Date.new(2026, 8, 25), interval: "1h")

      expect(
        a_request(:get, %r{api\.databursatil\.com/v2/intradia}).with(query: hash_including("intervalo" => "1h"))
      ).to have_been_made
    end
  end

  describe "#remaining_credits" do
    # The test environment uses a null store; production caches for real, so
    # these exercise a real store rather than asserting on a no-op.
    around do |example|
      original = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original
    end

    it "reads the balance from the provider" do
      stub_databursatil("/v2/creditos", { "disponibles" => 197_798 })

      expect(gateway.remaining_credits).to eq(197_798)
    end

    # Asking costs a credit, so asking repeatedly would spend the budget it reports.
    it "asks once and serves the rest from cache" do
      stub_databursatil("/v2/creditos", { "disponibles" => 197_798 })

      3.times { gateway.remaining_credits }

      expect(a_request(:get, %r{api\.databursatil\.com/v2/creditos})).to have_been_made.once
    end

    it "asks again when forced" do
      stub_databursatil("/v2/creditos", { "disponibles" => 197_798 })

      gateway.remaining_credits
      gateway.remaining_credits(force: true)

      expect(a_request(:get, %r{api\.databursatil\.com/v2/creditos})).to have_been_made.twice
    end
  end

  describe "error mapping" do
    it "distinguishes an invalid token from a malformed query" do
      stub_databursatil("/v2/cotizaciones", { "Error" => { "token" => [ "Longitud del token no valida." ] } }, status: 400)

      result = gateway.fetch_bulk_prices(%w[WALMEX.MX])

      expect(result.failure[0]).to eq(:unauthorized)
      expect(result.failure[1]).to include("Longitud del token")
    end

    it "names the parameter at fault when the query is wrong" do
      stub_databursatil("/v2/historicos", { "Error" => { "bolsa" => [ "Unknown field." ] } }, status: 400)

      result = gateway.fetch_historical("WALMEX.MX")

      expect(result.failure[0]).to eq(:invalid_request)
      expect(result.failure[1]).to include("bolsa")
    end
  end
end
