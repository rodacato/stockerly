module Assistant
  # /assistant: one conversation per visit, keyed by a token the page subscribes
  # to before the first question, so no streamed word is broadcast to nobody.
  class QuestionsController < AuthenticatedController
    SCREENS = NavigationHelper::MAIN_NAV.pluck(:key).freeze

    rate_limit to: 20, within: 1.minute, only: :create

    def new
      @token = SecureRandom.urlsafe_base64(16)
      query = params.permit(:symbol, :from, :q, :seen)
      @symbol = query[:symbol].presence&.upcase
      @from = query[:from].presence_in(SCREENS)
      @seen = query[:seen].to_s.split(",")
      @question = query[:q].to_s.squish.first(AssistantMessage::MAX_QUESTION)
      @connected = Administration::Queries::AssistantConnection.call&.dig(:status) == :connected
    end

    def create
      case Assistant::UseCases::AskQuestion.call(**question_params)
      in Dry::Monads::Success(message)
        render turbo_stream: [
          turbo_stream.remove("assistant_suggestions"),
          turbo_stream.append("assistant_messages", partial: "assistant/questions/message", locals: { message: message }),
          turbo_stream.replace("assistant_form", partial: "assistant/questions/form", locals: form_locals.merge(asked: true, autofocus: false))
        ]
      in Dry::Monads::Failure[ :not_connected ]
        redirect_to settings_assistant_path, alert: t(".sin_conexion")
      in Dry::Monads::Failure[ :validation, _ ]
        head :unprocessable_content
      end
    end

    private

    def question_params
      @question_params ||= params.expect(question: [ :question, :token, :symbol, :screen ]).to_h.symbolize_keys
                                 .then { |given| given.merge(screen: given[:screen].presence_in(SCREENS) || "hoy") }
    end

    def form_locals = { token: question_params[:token], symbol: question_params[:symbol], screen: question_params[:screen] }
  end
end
