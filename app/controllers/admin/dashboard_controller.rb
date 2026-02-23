module Admin
  class DashboardController < BaseController
    rate_limit to: 5, within: 1.minute, only: %i[refresh_fx_rates trigger_data_source]

    def show
      @total_assets   = Asset.count
      @syncing_assets = Asset.syncing.count
      @total_users    = User.count
      @recent_logs    = SystemLog.recent.limit(5)
      @error_logs_24h = SystemLog.errors.last_24h.count
      @integrations   = Integration.all
      @data_sources   = DataSourceRegistry.all

      result = Admin::Dashboard::LoadSyncOverview.call
      @sync_overview = result.value! if result.success?
    end

    def refresh_fx_rates
      RefreshFxRatesJob.perform_later
      redirect_to admin_root_path, notice: "FX rates refresh enqueued."
    end

    def trigger_data_source
      source = DataSourceRegistry.find(params[:key].to_sym)
      source.job_class.constantize.perform_later(*source.job_args)
      redirect_to admin_root_path, notice: "#{source.name} sync enqueued."
    rescue KeyError
      redirect_to admin_root_path, alert: "Unknown data source."
    end
  end
end
