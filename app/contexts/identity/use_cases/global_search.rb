module Identity
  module UseCases
    class GlobalSearch < ApplicationUseCase
      def call(query:, user: nil)
        return Success({ assets: [], alerts: [], news: [] }) if query.blank?

        q = "%#{query}%"

        assets = Asset.where("name ILIKE :q OR symbol ILIKE :q", q: q).limit(10)
        alerts = user ? user.alert_rules.where("asset_symbol ILIKE ?", q).limit(5) : []
        news = NewsArticle.where("title ILIKE :q OR related_ticker ILIKE :q", q: q).order(published_at: :desc).limit(5)

        Success({ assets: assets, alerts: alerts, news: news })
      end
    end
  end
end
