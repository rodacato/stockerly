module Administration
  module UseCases
    module Logs
      class ListLogs < SimpleUseCase
        include Pagy::Method

        KNOWN_MODULES = %w[sync alerts auth admin].freeze
        RANGE_KEYS    = %w[hoy 24h 7d 30d 90d].freeze
        DEFAULT_RANGE = "24h".freeze
        CREATED_AT_SINCE = "created_at >= ?".freeze

        def call(params: {}, request: nil)
          scope = SystemLog.recent
          scope = scope.where(severity: params[:severity]) if params[:severity].present?
          scope = scope.by_module(params[:module_name])
          scope = apply_search(scope, params[:search])
          scope = apply_range(scope, params[:range].presence || DEFAULT_RANGE)

          pagy, logs = pagy(:offset, scope,
            limit: 50,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          # No unfiltered SystemLog.count: the header chip it fed is gone, and
          # the footer reports the filtered total pagy already carries.
          { pagy: pagy, logs: logs }
        end

        private

        # Escape LIKE meta-characters (% and _) so a search query like "50%"
        # doesn't match unintentionally (gemini review on #139).
        def apply_search(scope, query)
          return scope if query.blank?
          like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
          scope.where("task_name ILIKE :q OR error_message ILIKE :q", q: like)
        end

        def apply_range(scope, key)
          case key.to_s
          when "hoy" then scope.where(CREATED_AT_SINCE, Time.current.beginning_of_day)
          when "24h" then scope.where(CREATED_AT_SINCE, 24.hours.ago)
          when "7d"  then scope.where(CREATED_AT_SINCE, 7.days.ago)
          when "30d" then scope.where(CREATED_AT_SINCE, 30.days.ago)
          when "90d" then scope.where(CREATED_AT_SINCE, 90.days.ago)
          else            scope
          end
        end
      end
    end
  end
end
