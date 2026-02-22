class NewsController < AuthenticatedController
  include Pagy::Backend

  def index
    result = News::ListArticles.call(params: filter_params)

    case result
    in Dry::Monads::Success(data)
      @pagy     = data[:pagy]
      @articles = data[:articles]
    end
  end

  private

  def filter_params
    params.permit(:ticker, :search, :page).to_h.symbolize_keys
  end
end
