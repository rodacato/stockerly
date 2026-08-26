# In-memory registry for all external data sources.
# Follows the same pattern as EventBus — boot-time registration,
# class-level accessor, and clear! for tests.
class DataSourceRegistry
  AmbiguousHealthCheck = Class.new(StandardError)

  DataSource = Data.define(
    :key,               # Symbol, e.g. :alpaca_us
    :name,              # Human label, e.g. "US Stocks — Alpaca"
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
    :health_check,      # True when this source is the one that answers for its integration
    :maintainer_only    # True when the credential only works for pre-existing accounts
  )

  @sources = {}

  class << self
    def register(key, health_check: false, maintainer_only: false, **attrs)
      @sources[key] = DataSource.new(key: key, health_check: health_check, maintainer_only: maintainer_only, **attrs)
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

    def for_capability(capability)
      @sources.values.select { |ds| ds.capabilities.include?(capability) }
    end

    def keys
      @sources.keys
    end

    def clear!
      @sources = {}
    end
  end
end
