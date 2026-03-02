module Alerts
  module UseCases
    class CreateRule < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Alerts::Contracts::CreateContract, params)
        rule  = yield persist(user, attrs)

        Success(rule)
      end

      private

      def persist(user, attrs)
        rule = user.alert_rules.create!(
          asset_symbol: attrs[:asset_symbol].upcase,
          condition: attrs[:condition],
          threshold_value: attrs[:threshold_value],
          status: :active
        )
        Success(rule)
      rescue ActiveRecord::RecordInvalid => e
        Failure([ :validation, e.record.errors.to_hash ])
      end
    end
  end
end
