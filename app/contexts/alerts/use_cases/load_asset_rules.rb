module Alerts
  module UseCases
    # Read API: a rule binds to a symbol, not to an asset id, and no caller
    # outside Alerts should have to know that.
    class LoadAssetRules < SimpleUseCase
      LIMIT = 3

      def call(user:, symbol:)
        user.alert_rules.where(asset_symbol: symbol).order(created_at: :desc).limit(LIMIT)
      end
    end
  end
end
