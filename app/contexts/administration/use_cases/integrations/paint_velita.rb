module Administration
  module UseCases
    module Integrations
      # Velita's colour (D173), one of the colours that carry no verdict.
      class PaintVelita < SimpleUseCase
        def call(colour:)
          return false unless Queries::AssistantConnection::VELITA_COLOURS.include?(colour)

          row = Integration.find_by!(provider_name: Queries::AssistantConnection::PROVIDER_NAME)
          row.update!(settings: row.settings.to_h.merge("velita_colour" => colour))
        end
      end
    end
  end
end
