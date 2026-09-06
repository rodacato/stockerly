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

  describe "the three financial statements" do
    let(:payload) do
      { "annual_reports" => [ { "fiscal_date_ending" => "2026-01-31", "reported_currency" => "USD",
                                "total_debt" => "11040000000", "short_term_debt" => "999000000",
                                "long_term_debt" => "7469000000",
                                "total_shareholder_equity" => "157293000000" } ],
        "quarterly_reports" => [ { "fiscal_date_ending" => "2025-10-26", "reported_currency" => "USD" } ] }
    end

    # D109: Alpha Vantage's free tier refuses BALANCE_SHEET as premium, which
    # left debt_to_equity, current_ratio and quick_ratio empty on every asset.
    it "returns the balance sheet in the shape the sync job persists" do
      stub_bridge(payload)

      result = gateway.fetch_balance_sheet("NVDA")

      expect(result).to be_success
      expect(result.value![:symbol]).to eq("NVDA")
      expect(result.value!.dig(:annual_reports, 0, "fiscal_date_ending")).to eq("2026-01-31")
      expect(result.value!.dig(:quarterly_reports, 0, "reported_currency")).to eq("USD")
    end

    # The keys are aliased to Alpha Vantage's names in the bridge, because
    # FundamentalCalculator reads those and must not learn a second vocabulary.
    it "carries the keys FundamentalCalculator reads, not Yahoo's own labels" do
      stub_bridge(payload)

      report = gateway.fetch_balance_sheet("NVDA").value![:annual_reports].first

      expect(report).to include("short_term_debt", "long_term_debt", "total_shareholder_equity")
    end

    it "asks the bridge for the statement it was asked for" do
      stub_bridge(payload)

      gateway.fetch_income_statement("NVDA")
      expect(PythonRunner).to have_received(:call).with("yahoo.py", "income_statement", "NVDA")

      gateway.fetch_cash_flow("NVDA")
      expect(PythonRunner).to have_received(:call).with("yahoo.py", "cash_flow", "NVDA")
    end

    it "passes a bridge failure through rather than returning empty reports" do
      stub_bridge_failure(:not_found)

      expect(gateway.fetch_balance_sheet("NVDA")).to be_failure
    end
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

    it "asks for everything when the backfill window passes what the ladder can say" do
      stub_bridge([])
      # This used to assert the opposite. The ladder tops out at 2y, so once
      # DAYS became ten years "max" is the honest answer rather than a window
      # silently truncated to a fifth of what was asked for. Still asserted
      # through DAYS, so a change to it is still visible here.
      expect(PythonRunner).to receive(:call).with("yahoo.py", "history", "WALMEX.MX", "max")
        .and_return(Dry::Monads::Success([]))

      gateway.fetch_historical("WALMEX.MX", BackfillPriceHistoryJob::DAYS.days.ago.to_date, Date.current)
    end
  end

  # The bug this pins was invisible to every spec above: they stub the bridge
  # by symbol, so asking for a ticker Yahoo does not have still came back
  # Success. What has to be asserted is the symbol Yahoo is ASKED for.
  describe "the symbol Yahoo is asked for" do
    it "puts the caret back on an index the catalogue stores without one" do
      stub_bridge([])
      expect(PythonRunner).to receive(:call).with("yahoo.py", "history", "^VIX", anything)
        .and_return(Dry::Monads::Success([]))

      gateway.fetch_historical("VIX")
    end

    it "does it for every index in the map, not only the one that was reported" do
      described_class::INDEX_SYMBOL_MAP.each do |yahoo_symbol, stored_symbol|
        stub_bridge({ "price" => "1", "change_percent" => "0", "volume" => nil, "as_of" => nil })
        expect(PythonRunner).to receive(:call).with("yahoo.py", "quote", yahoo_symbol)
          .and_return(Dry::Monads::Success({ "price" => "1", "change_percent" => "0" }))

        gateway.fetch_price(stored_symbol)
      end
    end

    it "leaves an ordinary ticker alone" do
      stub_bridge([])
      expect(PythonRunner).to receive(:call).with("yahoo.py", "history", "WALMEX.MX", anything)
        .and_return(Dry::Monads::Success([]))

      gateway.fetch_historical("WALMEX.MX")
    end

    # SyncIndexHistoryJob addresses the same indices by Yahoo's own ticker, so
    # both directions have to survive the same translation.
    it "leaves Yahoo's own ticker alone, which the index sync still passes" do
      stub_bridge([])
      expect(PythonRunner).to receive(:call).with("yahoo.py", "history", "^GSPC", anything)
        .and_return(Dry::Monads::Success([]))

      gateway.fetch_historical("^GSPC")
    end

    it "reports the symbol it was asked about, not the one it asked Yahoo" do
      stub_bridge({ "price" => "14.33", "change_percent" => "-1.2" })

      expect(gateway.fetch_price("VIX").value!).to include(symbol: "VIX")
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
