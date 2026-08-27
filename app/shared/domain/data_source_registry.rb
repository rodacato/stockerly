# In-memory registry for all external data sources.
# Follows the same pattern as EventBus — boot-time registration,
# class-level accessor, and clear! for tests.
class DataSourceRegistry
  AmbiguousHealthCheck = Class.new(StandardError)

  DataSource = Data.define(
    :key,               # Symbol, e.g. :alpaca_us
    :icon,              # Material Symbol name, e.g. "show_chart"
    :color,             # Tailwind color prefix, e.g. "indigo"
    :gateway_class,     # String class name, e.g. "AlpacaGateway"
    :job_class,         # String class name for sync, e.g. "SyncAllAssetsJob"
    :job_args,          # Array of args to pass to the job, e.g. ["stock"]
    :test_symbol,       # Symbol used for connectivity test, e.g. "AAPL"
    :test_method,       # Gateway method for connectivity test, e.g. :fetch_price
    :integration_name,  # Matches Integration#provider_name, e.g. "Alpaca"
    :circuit_breaker_key, # Key for CircuitBreaker lookup, e.g. "stock"
    :capabilities,      # Array of capability symbols, e.g. [:prices, :news, :earnings]
    :markets,           # Markets served, e.g. [:mx]. nil serves any.
    :asset_types,       # Asset types served, e.g. [:stock]. nil serves any.
    :health_check,      # True when this source is the one that answers for its integration
    :maintainer_only    # True when the credential only works for pre-existing accounts
  )

  # The label is not a member: it is copy a person reads, so it lives in the
  # locale under `data_sources.<key>` like every other such string (#302,
  # ADR-011). Provider proper nouns — Alpaca, Banxico, CoinGecko — read the
  # same in any locale and simply sit inside that string.
  class DataSource
    def name
      I18n.t("data_sources.#{key}")
    end
  end

  @sources = {}

  class << self
    def register(key, health_check: false, maintainer_only: false, markets: nil, asset_types: nil, **attrs)
      @sources[key] = DataSource.new(
        key: key, health_check: health_check, maintainer_only: maintainer_only,
        markets: markets, asset_types: asset_types, **attrs
      )
    end

    def find(key)
      @sources.fetch(key) { raise KeyError, "Unknown data source: #{key}" }
    end

    def all
      @sources.values
    end

    # An integration fronting several sources has to name the one that answers
    # for it; falling back on registration order would make file position the
    # decision. One source needs no marker, since there is nothing to choose.
    def for_integration(provider_name)
      matches = @sources.values.select { |ds| ds.integration_name == provider_name }
      return matches.first if matches.size <= 1

      matches.find(&:health_check) ||
        raise(AmbiguousHealthCheck, "#{provider_name} has #{matches.size} sources and none sets health_check")
    end

    # Asset type is applied before market, which is the precedence Adrian
    # chose: crypto is global, so a Mexican crypto goes to the crypto source
    # rather than down the BMV chain. A nil declaration serves anything.
    def for_capability(capability, market: nil, asset_type: nil)
      sources = @sources.values.select { |ds| ds.capabilities.include?(capability) }
      sources = sources.select { |ds| serves?(ds.asset_types, asset_type) } if asset_type
      sources = sources.select { |ds| serves?(ds.markets, market) } if market
      sources
    end

    def keys
      @sources.keys
    end

    def serves?(declared, wanted)
      declared.nil? || declared.include?(wanted.to_sym)
    end

    def clear!
      @sources = {}
    end

    # The registry is global and filled once at boot, so a spec that registers
    # a source hands it to every spec that runs after it. `clear!` cannot undo
    # that — it would empty what the initializer put there.
    def snapshot = @sources.dup

    def restore(snapshot)
      @sources = snapshot.dup
    end
  end
end
