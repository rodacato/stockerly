class MarketController < AuthenticatedController
  def index
    result = MarketData::UseCases::ExploreAssets.call(params: filter_params, request: request)

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
    result = MarketData::UseCases::LoadAssetDetail.call(symbol: params[:symbol])

    case result
    in Dry::Monads::Success(data)
      @asset = data[:asset]
      @presenter = data[:presenter]
      @has_fundamentals = data[:has_fundamentals]
      @has_statements = data[:has_statements]
      @yield_data = data[:yield_data]
      @price_histories = data[:price_histories] || []
      @pe_history = data[:pe_history]
      @dividends = data[:dividends] || []
      @company_overview = data[:company_overview]
      @is_watchlisted = current_user.watchlist_items.exists?(asset_id: @asset.id)
      @recent_observations = @asset.technical_observations.recent.within_last(30).limit(5)
      # ADR-014: the state is derived, the phrase is selected, neither is composed here.
      @state = MarketData::Domain::AssetState.for(@recent_observations)
      @state_source = MarketData::Domain::AssetState.source(@recent_observations)
      @holding = current_user.portfolio&.open_positions&.exists?(asset_id: @asset.id) || false

      trigger_fundamental_sync(@asset) unless @has_fundamentals
    in Dry::Monads::Failure[ :not_found, _ ]
      redirect_to market_path, alert: "Activo no encontrado"
    end
  end

  def earnings_tab
    @asset = Asset.find_by!(symbol: params[:symbol].upcase)
    @earnings_events = @asset.earnings_events.order(report_date: :desc).limit(8)
    render layout: false
  end

  def statements_tab
    @asset = Asset.find_by!(symbol: params[:symbol].upcase)
    render layout: false
  end

  private

  def filter_params
    params.permit(:type, :sector, :search, :page, :country, :exchange).to_h.symbolize_keys
  end

  def build_market_status
    { us: MarketHours.us_market_open?, bmv: MarketHours.bmv_market_open?, crypto: true }
  end

  def trigger_fundamental_sync(asset)
    return unless asset.asset_type_stock? || asset.asset_type_etf?
    return if asset.fundamentals_synced_at.present? && asset.fundamentals_synced_at > 10.minutes.ago

    SyncFundamentalJob.perform_later(asset.id)
  end
end
