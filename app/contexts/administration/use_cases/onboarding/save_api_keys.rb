module Administration
  module UseCases
    module Onboarding
      class SaveApiKeys < ApplicationUseCase
        BANXICO = "Banxico".freeze

        def call(keys:)
          updated = 0

          banxico = false

          keys.each do |integration_id, api_key_value|
            next if api_key_value.blank?

            integration = Integration.find_by(id: integration_id)
            next unless integration

            integration.update!(api_key_encrypted: api_key_value)
            integration.update!(connection_status: :connected) unless integration.connected?
            banxico ||= integration.provider_name == BANXICO
            updated += 1
          end

          Success({ updated: updated, fx: banxico ? pull_fx_history : :skipped })
        end

        private

        # Banxico is the first key the wizard can actually exercise, so pulling
        # the fix proves the token works and leaves real dated history behind.
        def pull_fx_history
          result = MarketData::UseCases::SyncFxHistory.call

          result.success? ? result.value![:stored] : :failed
        end
      end
    end
  end
end
