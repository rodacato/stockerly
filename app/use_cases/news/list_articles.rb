module News
  class ListArticles < ApplicationUseCase
    include Pagy::Backend

    def call(params: {})
      scope = NewsArticle.order(published_at: :desc)
      scope = scope.for_ticker(params[:ticker]) if params[:ticker].present?
      scope = scope.for_source(params[:source]) if params[:source].present?
      scope = scope.published_after(time_boundary(params[:time_range])) if params[:time_range].present?
      scope = scope.where("title ILIKE :q OR summary ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?

      pagy, articles = pagy(scope, limit: 12, page: params[:page] || 1)

      Success({ pagy: pagy, articles: articles })
    end

    private

    def time_boundary(range)
      case range
      when "1h"  then 1.hour.ago
      when "24h" then 24.hours.ago
      when "7d"  then 7.days.ago
      when "30d" then 30.days.ago
      end
    end
  end
end
