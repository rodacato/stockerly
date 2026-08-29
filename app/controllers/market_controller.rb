class MarketController < AuthenticatedController
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
      @recent_observations = data[:recent_observations]
      @state = data[:state]
      @state_source = data[:state_source]
      @trend_source = data[:trend_source]
      @market_context = data[:market_context]

      # ADR-002 forbids MarketData reading Trading or Alerts, so the user-side
      # readings are composed here from their own contexts.
      @position_data = Trading::UseCases::LoadAssetPosition.call(user: current_user, asset: @asset)
      @holding = @position_data.present?
      @asset_rules = Alerts::UseCases::LoadAssetRules.call(user: current_user, symbol: @asset.symbol)
      @is_watchlisted = current_user.watchlist_items.exists?(asset_id: @asset.id)

      trigger_fundamental_sync(@asset) unless @has_fundamentals
    in Dry::Monads::Failure[ :not_found, _ ]
      redirect_to assets_path, alert: t("market.flash.no_encontrado")
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

  def trigger_fundamental_sync(asset)
    return unless asset.asset_type_stock? || asset.asset_type_etf?
    return if asset.fundamentals_synced_at.present? && asset.fundamentals_synced_at > 10.minutes.ago

    SyncFundamentalJob.perform_later(asset.id)
  end
end
