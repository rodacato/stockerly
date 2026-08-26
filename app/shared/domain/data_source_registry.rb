# In-memory registry for all external data sources.
# Follows the same pattern as EventBus — boot-time registration,
# class-level accessor, and clear! for tests.
class DataSourceRegistry
  DataSource = Data.define(
    :key,               # Symbol, e.g. :polygon_stocks
    :name,              # Human label, e.g. "US Stocks — Polygon.io"
    :icon,              # Material Symbol name, e.g. "show_chart"
    :color,             # Tailwind color prefix, e.g. "indigo"
    :gateway_class,     # String class name, e.g. "PolygonGateway"
    :job_class,         # String class name for sync, e.g. "SyncAllAssetsJob"
    :job_args,          # Array of args to pass to the job, e.g. ["stock"]
    :test_symbol,       # Symbol used for connectivity test, e.g. "AAPL"
    :test_method,       # Gateway method for connectivity test, e.g. :fetch_price
    :integration_name,  # Matches Integration#provider_name, e.g. "Polygon.io"
    :circuit_breaker_key, # Key for CircuitBreaker lookup, e.g. "stock"
    :capabilities,      # Array of capability symbols, e.g. [:prices, :news, :earnings]
    :health_check       # True when this source is the one that answers for its integration
  )

  @sources = {}

  class << self
    def register(key, health_check: false, **attrs)
      @sources[key] = DataSource.new(key: key, health_check: health_check, **attrs)
    end

    def find(key)
      @sources.fetch(key) { raise KeyError, "Unknown data source: #{key}" }
    end

    def all
      @sources.values
    end

    # An integration can front several sources. Without a marked one the answer
    # is whichever registered first, which is an accident rather than a choice.
    def for_integration(provider_name)
      matches = @sources.values.select { |ds| ds.integration_name == provider_name }
      matches.find(&:health_check) || matches.first
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
