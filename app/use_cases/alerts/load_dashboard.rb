module Alerts
  class LoadDashboard < ApplicationUseCase
    def call(user:)
      rules = user.alert_rules.order(created_at: :desc)
      events = user.alert_events.recent
      preference = user.alert_preference
      triggered_today = user.alert_events
                            .where("triggered_at >= ?", Date.current.beginning_of_day)
                            .count

      Success({
        rules: rules,
        events: events,
        preference: preference,
        triggered_today: triggered_today
      })
    end
  end
end
