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

  def fetch_index_quotes
    @gateways.each do |gateway|
      next unless gateway.respond_to?(:fetch_index_quotes)

      result = gateway.fetch_index_quotes
      return result if result.success?
    end

    Failure([ :all_gateways_failed, "All gateways failed for index quotes" ])
  end
end
