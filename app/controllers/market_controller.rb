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
      @yield_data = data[:yield_data]
      @price_histories = data[:price_histories] || []
      @pe_history = data[:pe_history]
      @dividends = data[:dividends] || []
      @ai_health_check = data[:ai_health_check]
      @is_watchlisted = current_user.watchlist_items.exists?(asset_id: @asset.id)

      trigger_fundamental_sync(@asset) unless @has_fundamentals
    in Dry::Monads::Failure[ :not_found, _ ]
      redirect_to market_path, alert: "Asset not found"
    end
  end

  def earnings_tab
    @asset = Asset.find_by!(symbol: params[:symbol].upcase)
    @earnings_events = @asset.earnings_events.order(report_date: :desc).limit(8)
    @earnings_narrative = compute_earnings_narrative(@asset, @earnings_events)
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

  def compute_earnings_narrative(asset, earnings_events)
    return nil if earnings_events.size < 2

    Rails.cache.fetch("earnings_narrative/#{asset.id}", expires_in: 7.days) do
      result = MarketData::Domain::EarningsNarrativeGenerator.generate(
        asset: asset, earnings_events: earnings_events
      )
      result.success? ? result.value! : nil
    end
  end

  def trigger_fundamental_sync(asset)
    return unless asset.asset_type_stock? || asset.asset_type_etf?
    return if asset.fundamentals_synced_at.present? && asset.fundamentals_synced_at > 10.minutes.ago

    SyncFundamentalJob.perform_later(asset.id)
  end
end
