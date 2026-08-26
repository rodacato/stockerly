module MarketData
  module Domain
    # Per-provider limits, applied when an Integration row is first created.
    #
    # It lives here because two callers need the same numbers — the sync task
    # and first-run setup — and they had drifted apart: setup was still seeding
    # Yahoo at 2,000 calls a day after the file said 5 a minute.
    #
    # Existing rows are never overwritten by these; a limit someone tuned is
    # theirs to keep. `stockerly:sync` reports the drift instead.
    module ProviderDefaults
      # Quota is 200,000 credits a month at one credit per KiB, and the provider
      # reports the balance itself, so the daily figure is only a guardrail.
      # Alpaca publishes 200 req/min and no daily cap — same reasoning.
      # Yahoo publishes no limit at all and blocks by TLS fingerprint: the
      # per-minute ceiling is our own restraint, and the daily one is nil
      # because inventing a number it never stated would be the defect A2 deleted.
      ALL = {
        "DataBursatil"   => { provider_type: "Mexican Stocks (BMV/BIVA)", requires_api_key: true, max_requests_per_minute: nil, daily_call_limit: 5_000 },
        "Alpaca"         => { provider_type: "US Stocks & Corporate Actions", requires_api_key: true, max_requests_per_minute: 200, daily_call_limit: 50_000 },
        "Finnhub"        => { provider_type: "Stocks & Market Data", requires_api_key: true, max_requests_per_minute: 60, daily_call_limit: 500 },
        "CoinGecko"      => { provider_type: "Cryptocurrency", requires_api_key: false, max_requests_per_minute: 30, daily_call_limit: 10_000, settings: { "pro_tier" => false } },
        "Yahoo Finance"  => { provider_type: "Indices & BMV Corporate Actions", requires_api_key: false, max_requests_per_minute: 5, daily_call_limit: nil },
        "Alternative.me" => { provider_type: "Sentiment", requires_api_key: false, max_requests_per_minute: nil, daily_call_limit: 100 },
        "Alpha Vantage"  => { provider_type: "Fundamentals", requires_api_key: true, max_requests_per_minute: 5, daily_call_limit: 25 },
        "FMP"            => { provider_type: "Dividends & Splits", requires_api_key: true, max_requests_per_minute: 10, daily_call_limit: 250 },
        "ExchangeRate"   => { provider_type: "FX Rates", requires_api_key: true, max_requests_per_minute: 10, daily_call_limit: 1_500 },
        "Banxico"        => { provider_type: "CETES & Fixed Income", requires_api_key: true, max_requests_per_minute: nil, daily_call_limit: 1_000 }
      }.freeze

      FALLBACK = { provider_type: "External API", requires_api_key: true, daily_call_limit: 500 }.freeze

      def self.for(provider_name)
        ALL.fetch(provider_name, FALLBACK)
      end

      def self.names
        ALL.keys
      end
    end
  end
end
