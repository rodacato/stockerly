module Assistant
  # /assistant: a conversation keyed by a token the page subscribes to before the
  # first question, so no streamed word is broadcast to nobody. `c` reopens one.
  class QuestionsController < AuthenticatedController
    SCREENS = (NavigationHelper::MAIN_NAV.pluck(:key) + VelitaHelper::PAGES.values).freeze

    rate_limit to: 20, within: 1.minute, only: :create

    def new
      query = params.permit(:symbol, :from, :q, :seen, :c)
      @conversation = Assistant::Queries::Conversations.find(query[:c]) if query[:c].present?
      @token = @conversation&.token || SecureRandom.urlsafe_base64(16)
      @symbol = @conversation ? @conversation.symbol : query[:symbol].presence&.upcase
      @from = (@conversation&.screen || query[:from]).presence_in(SCREENS)
      @seen = query[:seen].to_s.split(",")
      @question = query[:q].to_s.squish.first(AssistantMessage::MAX_QUESTION)
      connection = Administration::Queries::AssistantConnection.call
      @connected = connection&.dig(:status) == :connected
      @reads_holdings = @connected && connection[:read_holdings]
      @suggestions = helpers.assistant_suggestions(from: @from, symbol: @symbol, seen: @seen)
      @via = params[:via] == "help" ? "help" : "typed"
      record_opening
    end

    def create
      case Assistant::UseCases::AskQuestion.call(**question_params)
      in Dry::Monads::Success(message)
        Usage.record("question.sent", screen: question_params[:screen], via: params[:via])
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

    # ADR-032: what the drawer offered when it opened (D166), and whether a ? brought it.
    def record_opening
      return unless @connected

      Usage.record("help.ask_velita", screen: @from, figure: params[:figure]) if @via == "help"
      Usage.record("assistant.suggestion_shown", screen: @from) if @suggestions.any? && @question.blank? && @conversation.nil?
    end

    def question_params
      @question_params ||= params.expect(question: [ :question, :token, :symbol, :screen ]).to_h.symbolize_keys
                                 .then { |given| given.merge(screen: given[:screen].presence_in(SCREENS) || "hoy") }
    end

    def form_locals = { token: question_params[:token], symbol: question_params[:symbol], screen: question_params[:screen] }
  end
end
