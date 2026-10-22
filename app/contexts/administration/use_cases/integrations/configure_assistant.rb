module Administration
  module UseCases
    module Integrations
      # Saves where the assistant asks. A changed host, key or model has not
      # been verified, so the row goes back to disconnected until it is.
      class ConfigureAssistant < ApplicationUseCase
        def call(params:)
          attrs = yield validate(Administration::Contracts::Integrations::AssistantContract, params)

          persist(attrs)
        end

        private

        def persist(attrs)
          row = Integration.find_or_initialize_by(provider_name: Queries::AssistantConnection::PROVIDER_NAME)
          row.provider_type = Queries::AssistantConnection::PROVIDER_TYPE
          row.settings = row.settings.to_h.merge("base_url" => attrs[:base_url].chomp("/"), "model" => attrs[:model])
          row.api_key_encrypted = attrs[:api_key] if attrs[:api_key].present?
          row.connection_status = :disconnected if row.changed?
          return Failure([ :validation, row.errors.to_hash ]) unless row.save

          Success(row.id)
        end
      end
    end
  end
end
