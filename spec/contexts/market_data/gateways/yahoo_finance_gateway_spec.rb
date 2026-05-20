require "rails_helper"

RSpec.describe MarketData::Gateways::YahooFinanceGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_price" do
    context "when Yahoo Finance returns valid data" do
      before { stub_yahoo_finance_price("GENIUSSACV.MX", price: 25.50, change_percent: 1.25, volume: 500_000) }

      it "returns Success with parsed price data" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_success
        data = result.value!
        expect(data[:symbol]).to eq("GENIUSSACV.MX")
        expect(data[:price]).to eq(25.50.to_d)
        expect(data[:volume]).to eq(500_000)
        expect(data[:change_percent]).to be_a(BigDecimal)
      end
    end

    context "when symbol has no results" do
      before { stub_yahoo_finance_not_found("FAKE.MX") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_price("FAKE.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_yahoo_finance_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_yahoo_finance_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_index_quotes" do
    context "when Yahoo Finance returns valid index data" do
      before do
        stub_yahoo_index_quotes({
          "^GSPC" => { name: "S&P 500", value: 5214.33, change_percent: 0.42, is_open: true },
          "^IXIC" => { name: "NASDAQ Composite", value: 18322.40, change_percent: 1.15, is_open: true },
          "^MXX"  => { name: "IPC Mexico", value: 52180.50, change_percent: -0.30, is_open: false }
        })
      end

      it "returns Success with mapped index quotes" do
        result = gateway.fetch_index_quotes(%w[^GSPC ^IXIC ^MXX])

        expect(result).to be_success
        quotes = result.value!
        expect(quotes.size).to eq(3)
        expect(quotes.map { |q| q[:symbol] }).to contain_exactly("SPX", "NDX", "IPC")
      end

      it "maps Yahoo symbols to internal symbols" do
        result = gateway.fetch_index_quotes(%w[^GSPC ^IXIC ^MXX])
        spx = result.value!.find { |q| q[:symbol] == "SPX" }

        expect(spx[:name]).to eq("S&P 500")
        expect(spx[:value]).to eq(5214.33.to_d)
        expect(spx[:change_percent]).to be_within(0.01).of(0.42)
        expect(spx[:is_open]).to be true
      end
    end

    context "when no data returned" do
      before { stub_yahoo_index_quotes_empty }

      it "returns Failure with :not_found" do
        result = gateway.fetch_index_quotes(%w[^GSPC])

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_index_quotes(%w[^GSPC])

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#search_tickers" do
    context "when Yahoo returns results" do
      before do
        stub_yahoo_ticker_search("AAPL", results: [
          { "symbol" => "AAPL", "longname" => "Apple Inc.", "quoteType" => "EQUITY",
            "exchange" => "NMS", "exchDisp" => "NASDAQ" },
          { "symbol" => "AAPL.MX", "longname" => "Apple Inc.", "quoteType" => "EQUITY",
            "exchange" => "MEX", "exchDisp" => "Mexico" }
        ])
      end

      it "returns Success with parsed results" do
        result = gateway.search_tickers("AAPL")

        expect(result).to be_success
        expect(result.value!.size).to eq(2)
        expect(result.value!.first[:symbol]).to eq("AAPL")
        expect(result.value!.first[:name]).to eq("Apple Inc.")
        expect(result.value!.first[:quote_type]).to eq("EQUITY")
        expect(result.value!.first[:exchange]).to eq("NMS")
        expect(result.value!.first[:exchange_display]).to eq("NASDAQ")
      end
    end

    context "when no results found" do
      before { stub_yahoo_ticker_search("ZZZZZ", results: []) }

      it "returns Success with empty array" do
        result = gateway.search_tickers("ZZZZZ")

        expect(result).to be_success
        expect(result.value!).to eq([])
      end
    end

    context "when rate limited (429)" do
      before { stub_yahoo_ticker_search_error(status: 429) }

      it "returns Failure with :rate_limited" do
        result = gateway.search_tickers("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_yahoo_ticker_search_error(status: 500) }

      it "returns Failure with :gateway_error" do
        result = gateway.search_tickers("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v1/finance/search})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.search_tickers("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_earnings" do
    context "with a single confirmed earnings date and an estimate" do
      before do
        stub_yahoo_earnings("WALMEX.MX",
          dates: [ Date.new(2026, 5, 28) ],
          estimate: 1.24
        )
      end

      it "returns Success with one parsed event" do
        result = gateway.fetch_earnings("WALMEX.MX")

        expect(result).to be_success
        events = result.value!
        expect(events.length).to eq(1)
        expect(events.first).to include(
          report_date: Date.new(2026, 5, 28),
          fiscal_quarter: 2,
          fiscal_year: 2026,
          confirmed: true
        )
        expect(events.first[:estimated_eps]).to eq(1.24.to_d)
      end
    end

    context "always reports actual_eps as nil for upcoming events" do
      before do
        stub_yahoo_earnings("WALMEX.MX",
          dates: [ Date.new(2026, 5, 28) ],
          estimate: 1.24
        )
      end

      # Regression: calendarEvents only carries the UPCOMING report — Yahoo
      # has no `actual` field on this endpoint. An earlier version of
      # parse_earnings mistakenly assigned `earningsChart.currentQuarterEstimate`
      # (still an estimate) to actual_eps when earningsAverage was missing,
      # which made every upcoming row render as "Reportado".
      it "does not populate actual_eps from estimate-shaped fields" do
        event = gateway.fetch_earnings("WALMEX.MX").value!.first
        expect(event[:actual_eps]).to be_nil
      end
    end

    context "with an unconfirmed date range" do
      before do
        stub_yahoo_earnings("GFNORTEO.MX",
          dates: [ Date.new(2026, 7, 21), Date.new(2026, 7, 25) ],
          estimate: 5.42
        )
      end

      it "uses the upper bound and marks the event unconfirmed" do
        result = gateway.fetch_earnings("GFNORTEO.MX")

        expect(result).to be_success
        event = result.value!.first
        expect(event[:report_date]).to eq(Date.new(2026, 7, 25))
        expect(event[:confirmed]).to be false
      end
    end

    context "when the response carries no earnings block" do
      before { stub_yahoo_earnings("EMPTY.MX", dates: []) }

      it "returns Success with an empty array" do
        expect(gateway.fetch_earnings("EMPTY.MX").value!).to eq([])
      end
    end

    context "when the response has no quoteSummary result" do
      before { stub_yahoo_earnings_empty("UNKNOWN.MX") }

      it "returns Success([]) so the caller doesn't block" do
        result = gateway.fetch_earnings("UNKNOWN.MX")
        expect(result).to be_success
        expect(result.value!).to eq([])
      end
    end

    context "when rate limited (429)" do
      before { stub_yahoo_earnings_error("WALMEX.MX", status: 429) }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_earnings("WALMEX.MX")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_yahoo_earnings_error("WALMEX.MX", status: 500) }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_earnings("WALMEX.MX")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_bulk_prices" do
    before do
      stub_yahoo_finance_bulk({
        "GENIUSSACV.MX" => { price: 25.50, change_percent: 1.25, volume: 500_000 },
        "IVVPESO.MX" => { price: 48.30, change_percent: -0.50, volume: 200_000 }
      })
    end

    it "returns Success with array of price data" do
      result = gateway.fetch_bulk_prices(%w[GENIUSSACV.MX IVVPESO.MX])

      expect(result).to be_success
      expect(result.value!.size).to eq(2)
      expect(result.value!.map { |d| d[:symbol] }).to contain_exactly("GENIUSSACV.MX", "IVVPESO.MX")
    end
  end
end
