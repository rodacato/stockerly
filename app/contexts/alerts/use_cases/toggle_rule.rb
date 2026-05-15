module Alerts
  module UseCases
    # ADR-006: single-resource mutation with the canonical 404 failure path.
    # `find` raises ActiveRecord::RecordNotFound; the controller handles
    # that with a flash + redirect.
    class ToggleRule < SimpleUseCase
      def call(user:, rule_id:)
        rule = user.alert_rules.find(rule_id)
        rule.update!(status: rule.active? ? :paused : :active)
        rule
      end
    end
  end
end
