# Breakers are memoised per key for the life of the process, so one spec that
# trips a provider hands the open breaker to every spec that runs after it —
# and only in the orders where it happens to run first.
RSpec.configure do |config|
  config.before(:each) { GatewayChain.reset_breakers! }
end
