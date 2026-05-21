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

        events = user.alert_events.recent
        preference = user.alert_preference
        triggered_today = user.alert_events
                              .where("triggered_at >= ?", Date.current.beginning_of_day)
                              .count

        counts = {
          active: all_rules.where(status: :active).count,
          paused: all_rules.where(status: :paused).count,
          all:    all_rules.size
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
