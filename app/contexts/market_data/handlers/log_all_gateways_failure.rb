module MarketData
  module Handlers
    # Logs the failure; the sync job records it on the asset (last_sync_error).
    # It never transitions the asset's status.
    class LogAllGatewaysFailure
      def self.call(event)
        symbol   = event.is_a?(Hash) ? event[:symbol] : event.symbol
        gateways = event.is_a?(Hash) ? event[:attempted_gateways] : event.attempted_gateways

        SystemLog.create!(
          task_name: "All Gateways Failed: #{symbol}",
          module_name: "sync",
          severity: :error,
          error_message: "Attempted: #{Array(gateways).join(', ')}"
        )
      end
    end
  end
end
