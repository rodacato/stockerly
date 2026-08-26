require "rails_helper"

RSpec.describe MarketData::Gateways::AlpacaGateway do
  subject(:gateway) { described_class.new(api_key: "PKTESTKEYID:test-secret") }

  describe "#initialize" do
    it "reads the stored credential as KEY_ID:SECRET" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID:secret")

      expect { described_class.new }.not_to raise_error
    end

    it "refuses a credential missing the secret half" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID")

      expect { described_class.new }
        .to raise_error(MarketData::Gateways::ApiKeyNotConfiguredError, /KEY_ID:SECRET/)
    end
  end

  describe "#fetch_price" do
    it "fails as unentitled without spending a request" do
      result = gateway.fetch_price("AAPL")

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:no_entitlement)
      expect(a_request(:get, %r{data\.alpaca\.markets})).not_to have_been_made
    end
  end

  describe "#fetch_daily_bars" do
    it "returns parsed bars keyed by symbol" do
      stub_alpaca_bars({ "AAPL" => [ alpaca_bar(date: "2026-08-24", close: 310.34) ] })

      result = gateway.fetch_daily_bars(%w[AAPL], "2026-08-17", "2026-08-24")

      expect(result).to be_success
      bar = result.value!["AAPL"].first
      expect(bar[:date]).to eq(Date.new(2026, 8, 24))
      expect(bar[:close]).to eq(BigDecimal("310.34"))
    end

    it "asks for the consolidated tape and split-adjusted prices" do
      stub_alpaca_bars({ "AAPL" => [] })

      gateway.fetch_daily_bars(%w[AAPL], "2026-08-17", "2026-08-24")

      expect(
        a_request(:get, "https://data.alpaca.markets/v2/stocks/bars")
          .with(query: hash_including("feed" => "sip", "adjustment" => "all"))
      ).to have_been_made
    end

    it "never asks for a window inside the 15-minute wall" do
      stub_alpaca_bars({ "AAPL" => [] })

      gateway.fetch_daily_bars(%w[AAPL], 3.days.ago.to_date, Time.current)

      expect(
        a_request(:get, %r{data\.alpaca\.markets/v2/stocks/bars}).with { |req|
          Time.parse(req.uri.query_values["end"]) <= 14.minutes.ago
        }
      ).to have_been_made
    end

    it "follows pagination until the token runs out" do
      stub_request(:get, %r{data\.alpaca\.markets/v2/stocks/bars})
        .to_return(
          { status: 200, headers: { "Content-Type" => "application/json" },
            body: { bars: { "AAPL" => [ alpaca_bar(date: "2026-08-17") ] }, next_page_token: "page-2" }.to_json },
          { status: 200, headers: { "Content-Type" => "application/json" },
            body: { bars: { "AAPL" => [ alpaca_bar(date: "2026-08-18") ] }, next_page_token: nil }.to_json }
        )

      result = gateway.fetch_daily_bars(%w[AAPL], "2026-08-17", "2026-08-18")

      expect(result.value!["AAPL"].map { |b| b[:date] })
        .to eq([ Date.new(2026, 8, 17), Date.new(2026, 8, 18) ])
    end

    it "tags a 403 as a missing entitlement, not a generic gateway error" do
      stub_alpaca_recent_denied

      result = gateway.fetch_daily_bars(%w[AAPL], "2026-08-17", "2026-08-24")

      expect(result.failure[0]).to eq(:no_entitlement)
      expect(result.failure[1]).to include("recent SIP data")
    end

    it "tags a 429 as rate limited" do
      stub_alpaca_rate_limited

      expect(gateway.fetch_daily_bars(%w[AAPL], "2026-08-17", "2026-08-24").failure[0]).to eq(:rate_limited)
    end
  end

  describe "#fetch_historical" do
    it "returns the bars for the single symbol asked for" do
      stub_alpaca_bars({ "AAPL" => [ alpaca_bar(date: "2026-08-24", close: 310.34) ] })

      result = gateway.fetch_historical("AAPL", "2026-08-17", "2026-08-24")

      expect(result.value!.first[:close]).to eq(BigDecimal("310.34"))
    end

    # An unknown symbol answers 200 with an empty object, so absence has to be
    # derived from the payload rather than the status.
    it "reports an unknown symbol as not found despite the 200" do
      stub_alpaca_bars({})

      result = gateway.fetch_historical("WALMEX", "2026-08-17", "2026-08-24")

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end
  end

  describe "#fetch_dividends" do
    it "parses cash dividends into the shape FmpGateway returns" do
      stub_alpaca_dividends("AAPL", [
        { "ex_date" => "2020-08-07", "payable_date" => "2020-08-13", "rate" => 0.82, "symbol" => "AAPL" }
      ])

      result = gateway.fetch_dividends("AAPL")

      expect(result.value!).to eq([
        { ex_date: Date.new(2020, 8, 7), pay_date: Date.new(2020, 8, 13),
          amount_per_share: BigDecimal("0.82"), currency: "USD" }
      ])
    end

    it "skips entries with no ex-date or no rate" do
      stub_alpaca_dividends("AAPL", [ { "ex_date" => "", "rate" => 0.82 }, { "ex_date" => "2020-08-07" } ])

      expect(gateway.fetch_dividends("AAPL").value!).to be_empty
    end
  end

  describe "#fetch_splits" do
    # Payload taken verbatim from a live probe: AAPL's 2020 4:1 and NVDA's 2024 10:1.
    it "parses forward splits into the shape FmpGateway returns" do
      stub_alpaca_splits("AAPL", forward: [
        { "ex_date" => "2020-08-31", "new_rate" => 4, "old_rate" => 1,
          "payable_date" => "2020-08-28", "record_date" => "2020-08-24", "symbol" => "AAPL" }
      ])

      expect(gateway.fetch_splits("AAPL").value!)
        .to eq([ { date: Date.new(2020, 8, 31), numerator: 4, denominator: 1 } ])
    end

    it "merges reverse splits into the same series, oldest first" do
      stub_alpaca_splits("XYZ",
        forward: [ { "ex_date" => "2024-06-10", "new_rate" => 10, "old_rate" => 1 } ],
        reverse: [ { "ex_date" => "2021-03-01", "new_rate" => 1, "old_rate" => 20 } ])

      expect(gateway.fetch_splits("XYZ").value!.map { |s| s[:date] })
        .to eq([ Date.new(2021, 3, 1), Date.new(2024, 6, 10) ])
    end

    it "skips entries missing either side of the ratio" do
      stub_alpaca_splits("AAPL", forward: [ { "ex_date" => "2020-08-31", "new_rate" => 4 } ])

      expect(gateway.fetch_splits("AAPL").value!).to be_empty
    end
  end

  describe "#fetch_news" do
    it "parses articles and takes the first image" do
      stub_alpaca_news([
        { "headline" => "Nvidia moves", "summary" => "…", "source" => "benzinga",
          "url" => "https://example.test/a", "created_at" => "2026-08-26T14:50:53Z",
          "symbols" => [ "NVDA" ], "images" => [ { "size" => "large", "url" => "https://img.test/a.jpg" } ] }
      ])

      article = gateway.fetch_news(ticker: "NVDA", limit: 5).value!.first

      expect(article[:title]).to eq("Nvidia moves")
      expect(article[:image_url]).to eq("https://img.test/a.jpg")
      expect(article[:related_ticker]).to eq("NVDA")
    end

    it "drops items with no headline" do
      stub_alpaca_news([ { "summary" => "orphan" } ])

      expect(gateway.fetch_news(ticker: "NVDA").value!).to be_empty
    end
  end
end
