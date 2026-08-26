namespace :stockerly do
  desc "Sync code-defined integrations with database records (idempotent)"
  task sync: :environment do
    sync_integrations
  end

  # Integration defaults keyed by provider_name.
  # Only applied when CREATING a new record — existing records are never overwritten.
  INTEGRATION_DEFAULTS = {
    # Alpaca publishes 200 req/min and no daily cap; the daily figure is our own guardrail.
    # Quota is 200,000 credits a month at one credit per KiB; the provider reports
    # the balance itself, so the daily figure here is only a guardrail.
    "DataBursatil"   => { provider_type: "Mexican Stocks (BMV/BIVA)", requires_api_key: true, max_requests_per_minute: nil, daily_call_limit: 5_000 },
    "Alpaca"         => { provider_type: "US Stocks & Corporate Actions", requires_api_key: true, max_requests_per_minute: 200, daily_call_limit: 50_000 },
    "Polygon.io"     => { provider_type: "Stocks & Forex",       requires_api_key: true,  max_requests_per_minute: 5,   daily_call_limit: 500   },
    "Finnhub"        => { provider_type: "Stocks & Market Data",  requires_api_key: true,  max_requests_per_minute: 60,  daily_call_limit: 500   },
    "CoinGecko"      => { provider_type: "Cryptocurrency",        requires_api_key: false, max_requests_per_minute: 30,  daily_call_limit: 10_000, settings: { "pro_tier" => false } },
    # Yahoo publishes no limit and blocks by TLS fingerprint. The per-minute
    # ceiling is our own restraint; the daily one is nil because inventing a
    # number Yahoo never stated would be the same defect A2 deleted.
    "Yahoo Finance"  => { provider_type: "Indices & BMV Corporate Actions", requires_api_key: false, max_requests_per_minute: 5, daily_call_limit: nil },
    "Alternative.me" => { provider_type: "Sentiment",             requires_api_key: false, max_requests_per_minute: nil, daily_call_limit: 100   },
    "Alpha Vantage"  => { provider_type: "Fundamentals",          requires_api_key: true,  max_requests_per_minute: 5,   daily_call_limit: 25    },
    "FMP"            => { provider_type: "Dividends & Splits",    requires_api_key: true,  max_requests_per_minute: 10,  daily_call_limit: 250   },
    "ExchangeRate"   => { provider_type: "FX Rates",              requires_api_key: true,  max_requests_per_minute: 10,  daily_call_limit: 1_500 },
    "Banxico"        => { provider_type: "CETES & Fixed Income",  requires_api_key: true,  max_requests_per_minute: nil, daily_call_limit: 1_000 }
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
    report_limit_drift(provider_names)
    report_orphans(provider_names)
  end

  # Sync only ever creates, so a provider retired from the registry keeps its
  # row -- and its card in the admin -- long after the code that used it is gone.
  def report_orphans(provider_names)
    orphans = Integration.where.not(provider_name: provider_names).order(:provider_name)
    return if orphans.empty?

    puts "\nNo longer in the registry (delete from Admin > Integrations if retired):"
    orphans.each { |i| puts "  #{i.provider_name} -- #{i.provider_type}" }
  end

  # Defaults apply on create only, so an existing row keeps whatever it had.
  # That is deliberate -- it protects a tuned limit -- but silent drift is how a
  # provider ends up throttled to a number nobody chose.
  def report_limit_drift(provider_names)
    drifted = provider_names.filter_map do |name|
      defaults = INTEGRATION_DEFAULTS[name]
      next if defaults.nil?

      integration = Integration.find_by(provider_name: name)
      next if integration.nil?

      changes = %i[max_requests_per_minute daily_call_limit].filter_map do |field|
        next if integration.public_send(field) == defaults[field]

        "#{field}: #{integration.public_send(field).inspect} vs #{defaults[field].inspect}"
      end

      "  #{name} -- #{changes.join(', ')}" if changes.any?
    end

    return if drifted.empty?

    puts "\nLimits differ from the defaults in this file (kept as-is):"
    puts drifted
  end
end
