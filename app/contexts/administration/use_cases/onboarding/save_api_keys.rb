module Administration
  module UseCases
    module Onboarding
      class SaveApiKeys < ApplicationUseCase
        def call(keys:)
          updated = 0

          keys.each do |integration_id, api_key_value|
            next if api_key_value.blank?

            integration = Integration.find_by(id: integration_id)
            next unless integration

            integration.update!(api_key_encrypted: api_key_value, connection_status: :connected)
            updated += 1
          end

          Success({ updated: updated })
        end
      end
    end
  end
end
