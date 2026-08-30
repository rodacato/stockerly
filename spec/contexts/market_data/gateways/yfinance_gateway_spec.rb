require "rails_helper"

RSpec.describe MarketData::Gateways::YfinanceGateway do
  subject(:gateway) { described_class.new }

  # The bridge runs a subprocess, which WebMock cannot intercept, so the runner
  # is stubbed here rather than letting a spec reach Yahoo for real.
  def stub_bridge(payload)
    allow(PythonRunner).to receive(:call).and_return(Dry::Monads::Success(payload))
  end

  def stub_bridge_failure(tag, message = "boom")
    allow(PythonRunner).to receive(:call).and_return(Dry::Monads::Failure([ tag, message ]))
  end

  describe "#search_tickers" do
    it "maps the bridge payload to the shape Administration consumes" do
      stub_bridge([ { "symbol" => "ALAB", "name" => "Astera Labs, Inc.", "quote_type" => "EQUITY",
                      "exchange" => "NASDAQ", "sector" => "Technology" } ])

      result = gateway.search_tickers("Astera Labs")

      expect(result).to be_success
      expect(result.value!).to eq([ { symbol: "ALAB", name: "Astera Labs, Inc.",
                                      quote_type: "EQUITY", exchange: "NASDAQ", sector: "Technology" } ])
    end

    # "Nothing matched" and "the provider is down" have to stay different, or
    # the typeahead renders an error where it should render an empty list.
    it "answers an unmatched query with Success and an empty list" do
      stub_bridge([])

      expect(gateway.search_tickers("zzzz").value!).to eq([])
    end

    it "propagates a bridge failure" do
      stub_bridge_failure(:not_supported, "yfinance is not installed in this image")

      expect(gateway.search_tickers("AAPL").failure[0]).to eq(:not_supported)
    end
  end

  describe "#fetch_price" do
    it "returns the quote with the moment it describes" do
      stub_bridge({ "price" => 66_440.9, "change_percent" => 0.223, "volume" => 31_379_135,
                    "as_of" => "2026-08-26T00:00:00-06:00" })

      quote = gateway.fetch_price("^MXX").value!

      expect(quote[:price]).to eq(BigDecimal("66440.9"))
      expect(quote[:change_percent]).to eq(BigDecimal("0.223"))
      expect(quote[:as_of]).to eq(Time.zone.parse("2026-08-26T00:00:00-06:00"))
    end

    it "passes a failure from the bridge through untouched" do
      stub_bridge_failure(:not_found, "no data for NOSUCH")

      expect(gateway.fetch_price("NOSUCH").failure[0]).to eq(:not_found)
    end

    it "refuses to call the bridge when the provider budget is spent" do
      create(:integration, provider_name: "Yahoo Finance", daily_api_calls: 10, daily_call_limit: 10,
                           calls_reset_at: Time.current)
      expect(PythonRunner).not_to receive(:call)

      expect(gateway.fetch_price("^MXX").failure[0]).to eq(:rate_limited)
    end
  end

  describe "#fetch_historical" do
    it "maps bars into the shape the other gateways return" do
      stub_bridge([ { "date" => "2026-08-24", "open" => 47.0, "high" => 48.2, "low" => 46.9,
                      "close" => 47.76, "volume" => 1_000 } ])

      bar = gateway.fetch_historical("WALMEX.MX", 30.days.ago.to_date, Date.current).value!.first

      expect(bar).to eq({ date: Date.new(2026, 8, 24), open: BigDecimal("47.0"), high: BigDecimal("48.2"),
                          low: BigDecimal("46.9"), close: BigDecimal("47.76"), volume: 1_000 })
    end

    it "asks for a period wide enough for the days requested" do
      stub_bridge([])
      expect(PythonRunner).to receive(:call).with("yahoo.py", "history", "WALMEX.MX", "1y")
        .and_return(Dry::Monads::Success([]))

      gateway.fetch_historical("WALMEX.MX", 200.days.ago.to_date, Date.current)
    end

    it "keeps the backfill window bounded instead of asking for everything" do
      stub_bridge([])
      # Asserted against the ladder rather than a literal period, so a future
      # change to DAYS that falls through to "max" fails here.
      expect(PythonRunner).to receive(:call) do |_script, _command, _symbol, period|
        expect(period).not_to eq("max")
        Dry::Monads::Success([])
      end

      gateway.fetch_historical("WALMEX.MX", BackfillPriceHistoryJob::DAYS.days.ago.to_date, Date.current)
    end
  end

  describe "#fetch_earnings" do
    it "returns the estimate and the actual, which quoteSummary never could" do
      stub_bridge([ { "date" => 5.days.from_now.to_date.to_s, "hour" => 16,
                      "estimated_eps" => 0.72, "actual_eps" => nil },
                    { "date" => 20.days.ago.to_date.to_s, "hour" => 3,
                      "estimated_eps" => 0.65, "actual_eps" => 0.68 } ])

      events = gateway.fetch_earnings("WALMEX.MX").value!

      expect(events.first).to include(report_date: 5.days.from_now.to_date,
                                      timing: :after_market_close,
                                      estimated_eps: BigDecimal("0.72"),
                                      actual_eps: nil)
      expect(events.last).to include(timing: :before_market_open,
                                     actual_eps: BigDecimal("0.68"))
    end

    it "drops quarters beyond the history window rather than flooding the table" do
      stub_bridge([ { "date" => 2.years.ago.to_date.to_s, "hour" => 16,
                      "estimated_eps" => 0.5, "actual_eps" => 0.5 } ])

      expect(gateway.fetch_earnings("WALMEX.MX").value!).to be_empty
    end

    it "surfaces a ticker the bridge has no earnings for" do
      stub_bridge_failure(:not_found)

      expect(gateway.fetch_earnings("GENIUSSACV.MX").failure.first).to eq(:not_found)
    end
  end

  describe "#fetch_dividends" do
    it "returns the BMV dividends no sanctioned provider serves" do
      stub_bridge([ { "date" => "2025-12-16", "amount" => 0.58 } ])

      expect(gateway.fetch_dividends("WALMEX.MX").value!)
        .to eq([ { ex_date: Date.new(2025, 12, 16), pay_date: nil,
                   amount_per_share: BigDecimal("0.58"), currency: "MXN" } ])
    end
  end

  describe "#fetch_splits" do
    # Yahoo reports one ratio, so a 4:1 arrives as 4.0 and a 1-for-20 as 0.05.
    it "expands a forward split ratio" do
      stub_bridge([ { "date" => "2020-08-31", "ratio" => 4.0 } ])

      expect(gateway.fetch_splits("AAPL").value!)
        .to eq([ { date: Date.new(2020, 8, 31), numerator: 4, denominator: 1 } ])
    end

    it "expands a reverse split ratio" do
      stub_bridge([ { "date" => "2021-03-01", "ratio" => 0.05 } ])

      expect(gateway.fetch_splits("XYZ").value!)
        .to eq([ { date: Date.new(2021, 3, 1), numerator: 1, denominator: 20 } ])
    end

    it "drops a zero ratio rather than dividing by it" do
      stub_bridge([ { "date" => "2021-03-01", "ratio" => 0 } ])

      expect(gateway.fetch_splits("XYZ").value!).to be_empty
    end
  end
end
