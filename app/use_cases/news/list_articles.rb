module News
  class ListArticles < ApplicationUseCase
    include Pagy::Backend

    def call(params: {})
      scope = NewsArticle.order(published_at: :desc)
      scope = scope.for_ticker(params[:ticker]) if params[:ticker].present?
      scope = scope.where("title ILIKE :q OR summary ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?

      pagy, articles = pagy(scope, limit: 12, page: params[:page] || 1)

      Success({ pagy: pagy, articles: articles })
    end
  end
end
