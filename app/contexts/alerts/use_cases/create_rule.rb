module Alerts
  module UseCases
    class CreateRule < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Alerts::Contracts::CreateContract, params)
        rule  = yield persist(user, attrs)

        publish(Events::RuleCreated.new(
          rule_id:      rule.id,
          user_id:      user.id,
          asset_symbol: rule.asset_symbol,
          condition:    rule.condition.to_s
        ))

        Success(rule)
      end

      private

      def persist(user, attrs)
        rule = user.alert_rules.create!(
          asset_symbol: attrs[:asset_symbol].to_s.upcase.presence,
          condition: attrs[:condition],
          threshold_value: attrs[:threshold_value],
          window_days: attrs[:window_days],
          status: :active
        )
        Success(rule)
      rescue ActiveRecord::RecordInvalid => e
        Failure([ :validation, e.record.errors.to_hash ])
      end
    end
  end
end
