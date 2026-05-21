module Alerts
  module UseCases
    class LoadDashboard < ApplicationUseCase
      ALLOWED_FILTERS = %w[active paused all].freeze

      def call(user:, filter: "active")
        filter = ALLOWED_FILTERS.include?(filter.to_s) ? filter.to_s : "active"

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

        Success({
          rules: rules,
          events: events,
          preference: preference,
          triggered_today: triggered_today,
          counts: counts,
          filter: filter
        })
      end
    end
  end
end
