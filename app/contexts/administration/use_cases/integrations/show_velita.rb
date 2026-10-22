module Administration
  module UseCases
    module Integrations
      # Mostrar a Velita (D167). Stored beside the connection it depends on; the
      # layout shows her only while that connection answers.
      class ShowVelita < SimpleUseCase
        def call(visible:)
          row = Integration.find_by!(provider_name: Queries::AssistantConnection::PROVIDER_NAME)
          row.update!(settings: row.settings.to_h.merge("show_velita" => visible))
        end
      end
    end
  end
end
