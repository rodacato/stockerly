module Administration
  module Dashboard
    class LoadSyncOverview < ApplicationUseCase
      def call
        sync_logs = SystemLog.by_module("sync").last_24h

        Success({
          sync_counts: sync_logs.group(:severity).count,
          integrations: Integration.all,
          status_counts: Asset.group(:sync_status).count,
          stale_count: Asset.syncing.select(&:price_stale?).count,
          recent_errors: SystemLog.by_module("sync").errors.last_24h.recent.limit(5)
        })
      end
    end
  end
end
