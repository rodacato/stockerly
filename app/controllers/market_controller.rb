class MarketController < AuthenticatedController
  def show
    result = MarketData::UseCases::LoadAssetDetail.call(symbol: params[:symbol], range: params[:range])

    case result
    in Dry::Monads::Success(data)
      @asset = data[:asset]
      @presenter = data[:presenter]
      @has_fundamentals = data[:has_fundamentals]
      @has_statements = data[:has_statements]
      @yield_data = data[:yield_data]
      @price_histories = data[:price_histories] || []
      @chart_range = data[:chart_range]
      @pe_history = data[:pe_history]
      @dividends = data[:dividends] || []
      @company_overview = data[:company_overview]
      @recent_observations = data[:recent_observations]
      @state = data[:state]
      @state_source = data[:state_source]
      @market_context = data[:market_context]
      @day_change = data[:day_change]
      @news = data[:news] || []
      @reading = data[:reading]
      @range_52w = data[:range_52w]
      @signals = data[:signals] || []
      @layers = data[:layers]
      @indicator_series = data[:indicator_series]

      # ADR-002 forbids MarketData reading Trading or Alerts, so the user-side
      # readings are composed here from their own contexts.
      @position_data = Trading::UseCases::LoadAssetPosition.call(user: current_user, asset: @asset)
      @holding = @position_data.present?
      @returns = if @holding && current_user.portfolio
                   Trading::Domain::PositionReturns.new(current_user.portfolio, @asset,
                                                        currency: current_user.preferred_currency)
      end
      @asset_rules = Alerts::UseCases::LoadAssetRules.call(user: current_user, symbol: @asset.symbol)
      @is_watchlisted = current_user.watchlist_items.exists?(asset_id: @asset.id)
      @anchors = Trading::UseCases::LoadAssetAnchors.call(
        asset: @asset, position_data: @position_data, rules: @asset_rules
      )
    in Dry::Monads::Failure[ :not_found, _ ]
      redirect_to assets_path, alert: t("market.flash.no_encontrado")
    end
  end

  # CKP-7: a read no longer enqueues. The reader asks, and the block swaps
  # itself in when MarketData::Handlers::BroadcastFundamentalsUpdate fires.
  def request_fundamentals
    asset = Asset.find_by!(symbol: params[:symbol].upcase)
    pending = MarketData::UseCases::RequestFundamentalSync.call(asset: asset)

    render turbo_stream: turbo_stream.replace(
      "asset_fundamentals_#{asset.id}",
      partial: "market/fundamentals_block",
      locals: { asset: asset, presenter: nil, has_fundamentals: false, pending: pending }
    )
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

  # The frame is empty until this responds, so nothing reaches TradingView
  # until the reader asks (D66). That is also why the usage metric #606 owes
  # is written here: the request IS the mount.
  def tradingview
    @asset = Asset.find_by!(symbol: params[:symbol].upcase)
    raise ActiveRecord::RecordNotFound unless helpers.tradingview_available?(@asset)

    SystemLog.create!(task_name: "TradingView Chart", module_name: "tradingview",
                     severity: :success, error_message: @asset.symbol)
    render layout: false
  end
end
