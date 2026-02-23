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
    :integration_name,  # Matches Integration#provider_name, e.g. "Polygon.io"
    :circuit_breaker_key # Key for CircuitBreaker lookup, e.g. "stock"
  )

  @sources = {}

  class << self
    def register(key, **attrs)
      @sources[key] = DataSource.new(key: key, **attrs)
    end

    def find(key)
      @sources.fetch(key) { raise KeyError, "Unknown data source: #{key}" }
    end

    def all
      @sources.values
    end

    def for_integration(provider_name)
      @sources.values.find { |ds| ds.integration_name == provider_name }
    end

    def keys
      @sources.keys
    end

    def clear!
      @sources = {}
    end
  end
end
