module Admin
  class DashboardController < BaseController
    rate_limit to: 5, within: 1.minute, only: %i[refresh_fx_rates trigger_data_source]

    def show
      @total_assets    = Asset.count
      @assets_added_7d = Asset.where("created_at >= ?", 7.days.ago).count
      @syncing_assets  = Asset.syncing.count
      @total_users     = User.count
      @admin_users     = User.admin.count
      @recent_activity = SystemLog.recent.limit(20)
      @activity_total  = SystemLog.last_24h.count
      @error_logs_24h  = SystemLog.errors.last_24h.count
      @last_error      = SystemLog.errors.recent.first
      @integrations    = Integration.all
      @data_sources    = DataSourceRegistry.all

      result = Administration::UseCases::Dashboard::LoadSyncOverview.call
      @sync_overview = result.value! if result.success?

      health_result = Administration::UseCases::Dashboard::LoadHealthMetrics.call
      @health = health_result.value! if health_result.success?
    end

    def refresh_fx_rates
      RefreshFxRatesJob.perform_later
      redirect_to admin_root_path, notice: "Sincronización de tipos de cambio programada."
    end

    def trigger_data_source
      source = DataSourceRegistry.find(params[:key].to_sym)
      source.job_class.perform_later(*source.job_args)
      redirect_to admin_root_path, notice: "Sincronización de #{source.name} programada."
    rescue KeyError
      redirect_to admin_root_path, alert: "Fuente de datos desconocida."
    end
  end
end
