namespace :stockerly do
  desc "Sync code-defined integrations with database records (idempotent)"
  task sync: :environment do
    sync_integrations
  end

  # Integration defaults keyed by provider_name.
  # Only applied when CREATING a new record — existing records are never overwritten.
  INTEGRATION_DEFAULTS = {
    "Polygon.io"     => { provider_type: "Stocks & Forex",       requires_api_key: true,  max_requests_per_minute: 5,   daily_call_limit: 500   },
    "Finnhub"        => { provider_type: "Stocks & Market Data",  requires_api_key: true,  max_requests_per_minute: 60,  daily_call_limit: 500   },
    "CoinGecko"      => { provider_type: "Cryptocurrency",        requires_api_key: false, max_requests_per_minute: 30,  daily_call_limit: 10_000, settings: { "pro_tier" => false } },
    "Yahoo Finance"  => { provider_type: "Mexican Stocks & ETFs", requires_api_key: false, max_requests_per_minute: nil, daily_call_limit: 2_000 },
    "Alternative.me" => { provider_type: "Sentiment",             requires_api_key: false, max_requests_per_minute: nil, daily_call_limit: 100   },
    "CNN"            => { provider_type: "Sentiment",             requires_api_key: false, max_requests_per_minute: nil, daily_call_limit: 100   },
    "Alpha Vantage"  => { provider_type: "Fundamentals",          requires_api_key: true,  max_requests_per_minute: 5,   daily_call_limit: 25    },
    "FMP"            => { provider_type: "Dividends & Splits",    requires_api_key: true,  max_requests_per_minute: 10,  daily_call_limit: 250   },
    "ExchangeRate"   => { provider_type: "FX Rates",              requires_api_key: true,  max_requests_per_minute: 10,  daily_call_limit: 1_500 },
    "Banxico"        => { provider_type: "CETES & Fixed Income",  requires_api_key: true,  max_requests_per_minute: nil, daily_call_limit: 1_000 },
    "AI Intelligence" => { provider_type: "AI / LLM",            requires_api_key: true,  max_requests_per_minute: 10,  daily_call_limit: 100   }
  }.freeze

  def sync_integrations
    provider_names = DataSourceRegistry.all.map(&:integration_name).uniq
    created = 0

    provider_names.each do |name|
      defaults = INTEGRATION_DEFAULTS[name] || {
        provider_type: "External API",
        requires_api_key: true,
        daily_call_limit: 500
      }

      Integration.find_or_create_by!(provider_name: name) do |i|
        i.provider_type          = defaults[:provider_type]
        i.requires_api_key       = defaults[:requires_api_key]
        i.connection_status      = :disconnected
        i.max_requests_per_minute = defaults[:max_requests_per_minute]
        i.daily_call_limit       = defaults[:daily_call_limit]
        i.settings               = defaults[:settings] if defaults[:settings]
        created += 1
      end
    end

    existing = provider_names.size - created
    puts "Integrations: #{created} created, #{existing} already exist, #{Integration.count} total"
  end
end
