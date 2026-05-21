module Administration
  module UseCases
    module Logs
      class ListLogs < ApplicationUseCase
        include Pagy::Method

        KNOWN_MODULES = %w[sync alerts auth admin].freeze
        RANGE_KEYS    = %w[hoy 24h 7d 30d 90d].freeze
        DEFAULT_RANGE = "24h".freeze

        def call(params: {}, request: nil)
          scope = SystemLog.recent
          scope = scope.where(severity: params[:severity]) if params[:severity].present?
          scope = scope.by_module(params[:module_name])
          scope = scope.where("task_name ILIKE :q OR error_message ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
          scope = apply_range(scope, params[:range].presence || DEFAULT_RANGE)

          pagy, logs = pagy(:offset, scope,
            limit: 50,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          Success({
            pagy: pagy,
            logs: logs,
            total_count: SystemLog.count
          })
        end

        private

        def apply_range(scope, key)
          case key.to_s
          when "hoy" then scope.where("created_at >= ?", Time.current.beginning_of_day)
          when "24h" then scope.where("created_at >= ?", 24.hours.ago)
          when "7d"  then scope.where("created_at >= ?", 7.days.ago)
          when "30d" then scope.where("created_at >= ?", 30.days.ago)
          when "90d" then scope.where("created_at >= ?", 90.days.ago)
          else            scope
          end
        end
      end
    end
  end
end
