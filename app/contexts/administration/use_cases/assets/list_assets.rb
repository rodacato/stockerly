module Administration
  module UseCases
    module Assets
      class ListAssets < ApplicationUseCase
        include Pagy::Backend

        def call(params: {})
          scope = Asset.all
          scope = scope.where(asset_type: params[:type]) if params[:type].present?
          scope = scope.where(country: params[:country]) if params[:country].present?
          scope = scope.where("name ILIKE :q OR symbol ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
          scope = scope.order(symbol: :asc)

          pagy, assets = pagy(scope, limit: 20, page: params[:page] || 1)

          total_count   = Asset.count
          syncing_count = Asset.syncing.count

          Success({
            pagy: pagy,
            assets: assets,
            total_count: total_count,
            syncing_count: syncing_count
          })
        end
      end
    end
  end
end
