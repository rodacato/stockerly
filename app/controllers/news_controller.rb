class NewsController < AuthenticatedController
  def index
    result = MarketData::UseCases::ListArticles.call(user: current_user, params: filter_params, request: request)

    case result
    in Dry::Monads::Success(data)
      @pagy     = data[:pagy]
      @articles = data[:articles]
    end
  end

  private

  def filter_params
    params.permit(:ticker, :search, :source, :time_range, :page, :filter).to_h.symbolize_keys
  end
end
