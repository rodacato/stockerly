module Admin
  class DashboardController < BaseController
    def show
      @total_assets   = Asset.count
      @syncing_assets = Asset.syncing.count
      @total_users    = User.count
      @recent_logs    = SystemLog.recent.limit(5)
      @error_logs_24h = SystemLog.errors.last_24h.count
      @integrations   = Integration.all
    end
  end
end
