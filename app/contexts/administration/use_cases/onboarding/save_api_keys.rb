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

            default_key = integration.api_key_pools.find_by(is_default: true)
            if default_key
              default_key.update!(api_key_encrypted: api_key_value)
            else
              integration.api_key_pools.create!(
                name: "Default",
                api_key_encrypted: api_key_value,
                is_default: true,
                enabled: true
              )
            end
            integration.update!(connection_status: :connected) unless integration.connected?
            updated += 1
          end

          Success({ updated: updated })
        end
      end
    end
  end
end
