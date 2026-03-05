# Iterates through an ordered list of gateways, returning the first
# successful result. Skips gateways whose circuit breaker is open.
# Duck-types MarketDataGateway (same fetch_price interface).
class GatewayChain
  include Dry::Monads[:result]

  def initialize(gateways:, circuit_breakers: {})
    @gateways = gateways
    @circuit_breakers = circuit_breakers
  end

  def fetch_price(symbol)
    attempted = []

    @gateways.each do |gateway|
      breaker = @circuit_breakers[gateway.class.name]

      if breaker && breaker.state == :open
        attempted << gateway.class.name
        next
      end

      result = if breaker
                 breaker.call { gateway.fetch_price(symbol) }
      else
                 gateway.fetch_price(symbol)
      end

      if result.success?
        value = result.value!
        value[:data_source] = gateway.class.name
        return Success(value)
      end

      attempted << gateway.class.name
    end

    Failure([ :all_gateways_failed, "All gateways failed for #{symbol}", attempted ])
  end

  def fetch_overview(symbol)
    attempted = []

    @gateways.each do |gateway|
      next unless gateway.respond_to?(:fetch_overview)

      breaker = @circuit_breakers[gateway.class.name]

      if breaker && breaker.state == :open
        attempted << gateway.class.name
        next
      end

      result = if breaker
                 breaker.call { gateway.fetch_overview(symbol) }
      else
                 gateway.fetch_overview(symbol)
      end

      if result.success?
        value = result.value!
        value[:data_source] = gateway.class.name
        return Success(value)
      end

      attempted << gateway.class.name
    end

    Failure([ :all_gateways_failed, "All gateways failed for #{symbol}", attempted ])
  end

  def fetch_news(ticker: nil, limit: 20)
    attempted = []

    @gateways.each do |gateway|
      next unless gateway.respond_to?(:fetch_news)

      breaker = @circuit_breakers[gateway.class.name]

      if breaker && breaker.state == :open
        attempted << gateway.class.name
        next
      end

      result = if breaker
                 breaker.call { gateway.fetch_news(ticker: ticker, limit: limit) }
      else
                 gateway.fetch_news(ticker: ticker, limit: limit)
      end

      if result.success?
        return Success(result.value!)
      end

      attempted << gateway.class.name
    end

    Failure([ :all_gateways_failed, "All gateways failed for news", attempted ])
  end

  def fetch_earnings(ticker)
    attempted = []

    @gateways.each do |gateway|
      next unless gateway.respond_to?(:fetch_earnings)

      breaker = @circuit_breakers[gateway.class.name]

      if breaker && breaker.state == :open
        attempted << gateway.class.name
        next
      end

      result = if breaker
                 breaker.call { gateway.fetch_earnings(ticker) }
      else
                 gateway.fetch_earnings(ticker)
      end

      if result.success?
        return Success(result.value!)
      end

      attempted << gateway.class.name
    end

    Failure([ :all_gateways_failed, "All gateways failed for earnings: #{ticker}", attempted ])
  end

  def fetch_index_quotes
    @gateways.each do |gateway|
      next unless gateway.respond_to?(:fetch_index_quotes)

      result = gateway.fetch_index_quotes
      return result if result.success?
    end

    Failure([ :all_gateways_failed, "All gateways failed for index quotes" ])
  end

  # Builds a GatewayChain from DataSourceRegistry for the given capability.
  # Sources are tried in registration order (first registered = primary).
  # Deduplicates by gateway class and skips unconfigured gateways.
  def self.for_capability(capability)
    sources = DataSourceRegistry.for_capability(capability)
    return new(gateways: []) if sources.empty?

    seen = Set.new
    gateways = []
    breakers = {}

    sources.each do |source|
      klass = source.gateway_class
      next if seen.include?(klass)
      seen << klass

      begin
        gateways << klass.new
      rescue MarketData::Gateways::ApiKeyNotConfiguredError
        next
      end

      breakers[klass.name] = CircuitBreaker.new(
        name: "#{source.circuit_breaker_key}_gateway",
        threshold: 5,
        timeout: 60
      )
    end

    new(gateways: gateways, circuit_breakers: breakers)
  end
end
