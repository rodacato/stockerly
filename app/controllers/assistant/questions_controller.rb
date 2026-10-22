module Assistant
  # /assistant: one conversation per visit, keyed by a token the page subscribes
  # to before the first question, so no streamed word is broadcast to nobody.
  class QuestionsController < AuthenticatedController
    rate_limit to: 20, within: 1.minute, only: :create

    def new
      @token = SecureRandom.urlsafe_base64(16)
      @symbol = params[:symbol].presence&.upcase
      @connected = Administration::Queries::AssistantConnection.call&.dig(:status) == :connected
    end

    def create
      case Assistant::UseCases::AskQuestion.call(**question_params)
      in Dry::Monads::Success(message)
        render turbo_stream: [
          turbo_stream.append("assistant_messages", partial: "assistant/questions/message", locals: { message: message }),
          turbo_stream.replace("assistant_form", partial: "assistant/questions/form",
                                                 locals: { token: question_params[:token], symbol: question_params[:symbol], asked: true })
        ]
      in Dry::Monads::Failure[ :not_connected ]
        redirect_to settings_assistant_path, alert: t(".sin_conexion")
      in Dry::Monads::Failure[ :validation, _ ]
        head :unprocessable_content
      end
    end

    private

    def question_params
      params.expect(question: [ :question, :token, :symbol ]).to_h.symbolize_keys
    end
  end
end
