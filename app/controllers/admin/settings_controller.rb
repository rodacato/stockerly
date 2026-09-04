module Admin
  class SettingsController < BaseController
    TOGGLE_KEYS = %w[maintenance_mode auto_sync_enabled email_notifications_enabled developer_mode].freeze

    rate_limit to: 5, within: 1.minute, only: :trigger_data_source

    def show
      configs = SiteConfig.where(key: TOGGLE_KEYS).index_by(&:key)

      @maintenance_mode            = enabled?(configs["maintenance_mode"])
      @auto_sync_enabled           = enabled?(configs["auto_sync_enabled"])
      @email_notifications_enabled = enabled?(configs["email_notifications_enabled"])
      @developer_mode              = enabled?(configs["developer_mode"])

      @applied_at     = TOGGLE_KEYS.index_with { |key| configs[key]&.updated_at }
      @recent_changes = SiteConfigChange.recent.includes(:admin).limit(8)
      @diagnostics    = build_diagnostics
      @data_sources   = DataSourceRegistry.all
    end

    def trigger_data_source
      source = DataSourceRegistry.find(params.expect(:key).to_sym)
      source.job_class.perform_later(*source.job_args)
      redirect_to admin_settings_path, notice: t(".encolada", source: source.name)
    rescue KeyError
      redirect_to admin_settings_path, alert: t(".desconocida")
    end

    def update
      configs = SiteConfig.where(key: TOGGLE_KEYS).index_by(&:key)

      changes = TOGGLE_KEYS.each_with_object([]) do |key, memo|
        next unless params.key?(key)
        new_value = (params[key] == "1").to_s
        old_value = enabled?(configs[key]).to_s
        next if old_value == new_value
        memo << [ key, old_value, new_value ]
      end

      SiteConfig.transaction do
        changes.each do |key, old_value, new_value|
          SiteConfig.set(key, new_value == "true")
          SiteConfigChange.create!(key: key, old_value: old_value, new_value: new_value, admin: current_user)
        end
      end

      redirect_to admin_settings_path, notice: t("admin.settings.flash.guardados")
    end

    private

    def enabled?(config)
      config&.value == "true"
    end

    def build_diagnostics
      {
        version:     Stockerly::VERSION,
        ruby:        RUBY_VERSION,
        rails:       Rails.version,
        environment: Rails.env,
        solid_queue: solid_queue_summary,
        cache_entries: HealthMetrics.cache_entries,
        errors_last_24h: ErrorEvent.since(24.hours.ago).sum(:occurrences),
        # D31 gave Descubrir a kill criterion with a date. Reading it needs the
        # number on screen, not in a console.
        discover_weeks: MarketData::Discover::VisitLog.weeks_seen,
        discover_window: MarketData::Discover::VisitLog.window,
        discover_last_seen: MarketData::Discover::VisitLog.last_seen
      }
    end

    def solid_queue_summary
      active    = HealthMetrics.in_progress_jobs
      failed    = HealthMetrics.failed_jobs
      scheduled = HealthMetrics.scheduled_jobs
      return "—" if [ active, failed, scheduled ].all?(&:nil?)
      "#{active || 0} en proceso · #{failed || 0} fallidos · #{scheduled || 0} programados"
    rescue StandardError
      "—"
    end
  end
end
