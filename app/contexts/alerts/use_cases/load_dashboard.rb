module Alerts
  module UseCases
    class LoadDashboard < SimpleUseCase
      ALLOWED_FILTERS = %w[active paused all].freeze

      # Defaults to every rule. The screen used to carry Activas/Pausadas/Todas
      # tabs and default to active; `reglas-lista` draws one list where a paused
      # rule sits among the rest wearing a "pausada" pill. Keeping the old
      # default with the tabs gone would have hidden paused rules with no way
      # to reach them. The filter stays for a URL that asks for one.
      def call(user:, filter: "all")
        filter = ALLOWED_FILTERS.include?(filter.to_s) ? filter.to_s : "all"

        all_rules = user.alert_rules.order(created_at: :desc)
        rules = case filter
        when "active"  then all_rules.where(status: :active)
        when "paused"  then all_rules.where(status: :paused)
        else                all_rules
        end

        events = user.alert_events.recent.includes(:alert_rule)
        preference = user.alert_preference
        triggered_today = user.alert_events
                              .where("triggered_at >= ?", Date.current.beginning_of_day)
                              .count

        # Single GROUP BY status aggregation instead of three round-trips.
        counts_by_status = user.alert_rules.group(:status).count
        active_count = counts_by_status["active"].to_i
        paused_count = counts_by_status["paused"].to_i
        counts = {
          active: active_count,
          paused: paused_count,
          all:    active_count + paused_count
        }

        {
          rules: rules,
          events: events,
          preference: preference,
          triggered_today: triggered_today,
          counts: counts,
          filter: filter
        }
      end
    end
  end
end
