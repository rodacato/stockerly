module Administration
  module UseCases
    module Assets
      class ListAssets < ApplicationUseCase
        include Pagy::Method

        def call(params: {}, request: nil)
          scope = Asset.all
          scope = scope.where(asset_type: params[:type]) if params[:type].present?
          scope = scope.where(country: params[:country]) if params[:country].present?
          scope = scope.where(sync_status: params[:status]) if params[:status].present?
          scope = scope.where("name ILIKE :q OR symbol ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
          scope = scope.order(symbol: :asc)

          pagy, assets = pagy(:offset, scope,
            limit: 20,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

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
