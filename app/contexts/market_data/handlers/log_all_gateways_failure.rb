module MarketData
  module Handlers
    # Logs a critical SystemLog entry when all gateways fail for an asset.
    # Marks the asset as sync_issue after 3+ consecutive failures.
    class LogAllGatewaysFailure
      CONSECUTIVE_FAILURE_THRESHOLD = 3

      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        symbol   = event.is_a?(Hash) ? event[:symbol] : event.symbol
        gateways = event.is_a?(Hash) ? event[:attempted_gateways] : event.attempted_gateways

        SystemLog.create!(
          task_name: "All Gateways Failed: #{symbol}",
          module_name: "sync",
          severity: :error,
          error_message: "Attempted: #{Array(gateways).join(', ')}"
        )

        mark_sync_issue(asset_id, symbol)
      end

      def self.mark_sync_issue(asset_id, symbol)
        recent_failures = SystemLog.where(
          task_name: "All Gateways Failed: #{symbol}",
          module_name: "sync",
          severity: :error
        ).where("created_at > ?", 1.hour.ago).count

        return unless recent_failures >= CONSECUTIVE_FAILURE_THRESHOLD

        asset = Asset.find_by(id: asset_id)
        return unless asset

        asset.update!(
          sync_status: :sync_issue,
          sync_issue_since: asset.sync_issue_since || Time.current
        )
      end
      private_class_method :mark_sync_issue
    end
  end
end
