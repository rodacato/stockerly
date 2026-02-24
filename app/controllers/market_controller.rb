class MarketController < AuthenticatedController
  include Pagy::Backend

  def index
    result = Market::ExploreAssets.call(params: filter_params)

    case result
    in Dry::Monads::Success(data)
      @pagy    = data[:pagy]
      @assets  = data[:assets]
      @indices = data[:indices]
      @vix     = data[:vix]
      @market_status = build_market_status
      @watchlisted_asset_ids = current_user.watchlist_items.pluck(:asset_id).to_set
    end
  end

  def show
    result = Market::LoadAssetDetail.call(symbol: params[:symbol])

    case result
    in Dry::Monads::Success(data)
      @asset = data[:asset]
      @presenter = data[:presenter]
      @has_fundamentals = data[:has_fundamentals]
      @is_watchlisted = current_user.watchlist_items.exists?(asset_id: @asset.id)
    in Dry::Monads::Failure[ :not_found, _ ]
      redirect_to market_path, alert: "Asset not found"
    end
  end

  private

  def filter_params
    params.permit(:type, :sector, :search, :page, :country, :exchange).to_h.symbolize_keys
  end

  def build_market_status
    { us: MarketHours.us_market_open?, bmv: MarketHours.bmv_market_open?, crypto: true }
  end
end
