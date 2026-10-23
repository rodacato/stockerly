module Settings
  # Ajustes · Asistente (D167): where the assistant asks, and whether it answers.
  # The row is Administration's; the check is the assistant's (ADR-031 §4).
  class AssistantsController < AuthenticatedController
    rate_limit to: 10, within: 1.minute, only: [ :update, :verify ]

    def show
      @connection = Administration::Queries::AssistantConnection.call
    end

    def update
      case configure
      in Dry::Monads::Success
        redirect_to settings_assistant_path, notice: t(".guardada")
      in Dry::Monads::Failure[ :validation, errors ]
        render_invalid(errors)
      end
    end

    def verify
      case configure
      in Dry::Monads::Failure[ :validation, errors ]
        render_invalid(errors)
      in Dry::Monads::Success
        Assistant::UseCases::VerifyConnection.call
        redirect_to settings_assistant_path
      end
    end

    def velita
      Administration::UseCases::Integrations::ShowVelita.call(visible: params[:show_velita] == true)
      head :ok
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def holdings
      Administration::UseCases::Integrations::ShareHoldings.call(allowed: params[:read_holdings] == true)
      head :ok
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def appearance
      colour = params[:velita_colour].to_s
      Usage.record("velita.colour_changed", screen: "ajustes", colour: colour) if Administration::UseCases::Integrations::PaintVelita.call(colour: colour)
      redirect_to settings_assistant_path
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def configure
      Administration::UseCases::Integrations::ConfigureAssistant.call(params: assistant_params.to_h)
    end

    def render_invalid(errors)
      field, messages = errors.first
      flash.now[:alert] = "#{t("settings.assistants.show.campos.#{field}")} #{Array(messages).first}"
      @connection = Administration::Queries::AssistantConnection.call
      render :show, status: :unprocessable_content
    end

    def assistant_params
      params.expect(assistant: [ :base_url, :api_key, :planner_model, :model ])
    end
  end
end
