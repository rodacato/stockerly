module MarketData
  module Gateways
    # Each gateway declares its own retry budget; this only caps how long one
    # wait may last. The cap is what lets the test environment exercise a retry
    # without sleeping the backoff for real — the attempts still happen.
    module RetryPolicy
      def self.options(declared)
        cap = Rails.configuration.x.gateway_retry_max_interval
        return declared if cap.nil?

        declared.merge(max_interval: cap)
      end
    end
  end
end
