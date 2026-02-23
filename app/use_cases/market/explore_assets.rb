module Market
  class ExploreAssets < ApplicationUseCase
    include Pagy::Backend

    def call(params: {})
      scope = Asset.includes(:trend_scores)

      scope = scope.where(asset_type: params[:type]) if params[:type].present?
      scope = scope.by_sector(params[:sector])
      scope = scope.by_country(params[:country])
      scope = scope.where(exchange: params[:exchange]) if params[:exchange].present?
      scope = scope.where("name ILIKE :q OR symbol ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
      scope = scope.order(symbol: :asc)

      pagy, assets = pagy(scope, limit: 20, page: params[:page] || 1)

      indices = MarketIndex.major

      Success({ pagy: pagy, assets: assets, indices: indices })
    end
  end
end
