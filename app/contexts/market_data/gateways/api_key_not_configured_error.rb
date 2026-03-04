module MarketData
  module Gateways
    class ApiKeyNotConfiguredError < StandardError
      def initialize(provider_name, reason: nil)
        details = reason ? " (#{reason})" : ""
        super("API key not configured for #{provider_name}#{details}. Configure it via Admin > Integrations.")
      end
    end
  end
end
