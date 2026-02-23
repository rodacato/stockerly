module Admin
  class DashboardController < BaseController
    rate_limit to: 5, within: 1.minute, only: :refresh_fx_rates

    def show
      @total_assets   = Asset.count
      @syncing_assets = Asset.syncing.count
      @total_users    = User.count
      @recent_logs    = SystemLog.recent.limit(5)
      @error_logs_24h = SystemLog.errors.last_24h.count
      @integrations   = Integration.all

      result = Admin::Dashboard::LoadSyncOverview.call
      @sync_overview = result.value! if result.success?
    end

    def refresh_fx_rates
      RefreshFxRatesJob.perform_later
      redirect_to admin_root_path, notice: "FX rates refresh enqueued."
    end
  end
end
