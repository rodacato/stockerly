module Administration
  module UseCases
    module Assets
      class ListAssets < ApplicationUseCase
        include Pagy::Method

        KNOWN_MARKETS = %w[BMV NASDAQ NYSE Banxico COINGECKO].freeze

        def call(params: {}, request: nil)
          scope = Asset.all
          scope = scope.where(asset_type: params[:type]) if params[:type].present?
          scope = scope.where(country: params[:country]) if params[:country].present?
          scope = scope.where(sync_status: params[:status]) if params[:status].present?
          scope = apply_market_filter(scope, params[:market])
          scope = scope.where("name ILIKE :q OR symbol ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
          scope = scope.order(symbol: :asc)

          pagy, assets = pagy(:offset, scope,
            limit: 20,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          Success({
            pagy: pagy,
            assets: assets,
            total_count: Asset.count,
            syncing_count: Asset.syncing.count
          })
        end

        private

        def apply_market_filter(scope, market)
          return scope if market.blank?

          if market == "Otros"
            scope.where.not(exchange: KNOWN_MARKETS).or(scope.where(exchange: nil))
          elsif KNOWN_MARKETS.include?(market)
            scope.where(exchange: market)
          else
            scope
          end
        end
      end
    end
  end
end
