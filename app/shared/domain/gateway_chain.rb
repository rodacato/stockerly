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

      wanted = symbol_for(gateway, symbol)

      result = if breaker
                 breaker.call { gateway.fetch_price(wanted) }
      else
                 gateway.fetch_price(wanted)
      end

      if result.success?
        value = result.value!
        value[:data_source] = gateway.class.name
        value[:source] ||= gateway.source_id
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

  def fetch_dividends(symbol) = first_answer(:fetch_dividends, symbol)

  def fetch_splits(symbol) = first_answer(:fetch_splits, symbol)

  # The five methods above each spell this loop out; these two share it. The
  # older five differ in what they stamp on the value, which is why they stay.
  def first_answer(method, symbol)
    attempted = []

    @gateways.each do |gateway|
      next unless gateway.respond_to?(method)

      breaker = @circuit_breakers[gateway.class.name]

      if breaker&.state == :open
        attempted << gateway.class.name
        next
      end

      wanted = symbol_for(gateway, symbol)
      result = breaker ? breaker.call { gateway.public_send(method, wanted) } : gateway.public_send(method, wanted)

      return result if result.success?

      attempted << gateway.class.name
    end

    Failure([ :all_gateways_failed, "All gateways failed for #{method}: #{symbol}", attempted ])
  end

  # Callers may pass a plain symbol or a provider => symbol map, so each
  # gateway in the chain receives the name its provider actually answers to.
  def symbol_for(gateway, symbol)
    return symbol unless symbol.is_a?(Hash)

    provider = gateway.class.const_defined?(:PROVIDER) ? gateway.class::PROVIDER : nil
    symbol[provider] || symbol["default"]
  end

  # Breakers are memoized per key, not built per call: a breaker rebuilt on
  # every fetch is always closed, which is a breaker that never opens.
  BREAKERS = {}

  def self.breaker_for(key)
    BREAKERS[key] ||= CircuitBreaker.new(name: "#{key}_gateway", threshold: 5, timeout: 60)
  end

  def self.reset_breakers!
    BREAKERS.each_value(&:reset!)
  end

  # Builds a GatewayChain from DataSourceRegistry for the given capability,
  # narrowed by the market and asset type when the caller knows them. Sources
  # are tried in registration order (first registered = primary).
  def self.for_capability(capability, market: nil, asset_type: nil)
    sources = DataSourceRegistry.for_capability(capability, market: market, asset_type: asset_type)
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

      breakers[klass.name] = breaker_for(source.circuit_breaker_key)
    end

    new(gateways: gateways, circuit_breakers: breakers)
  end
end
