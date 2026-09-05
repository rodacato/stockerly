module MarketData
  module UseCases
    class LoadAssetDetail < ApplicationUseCase
      # The chart's windows (CKP-2). The heading, the control and the query all
      # read this one map, so what the chart says it plots is what it plots.
      # `nil` is the whole series, which is what MAX means.
      RANGES = {
        "1S"  => -> { 1.week.ago.to_date },
        "1M"  => -> { 1.month.ago.to_date },
        "3M"  => -> { 3.months.ago.to_date },
        "1A"  => -> { 1.year.ago.to_date },
        "MAX" => -> { nil }
      }.freeze

      # The artboard leads with 3M, and the table now holds years rather than
      # the thirty days the old fixed window assumed (X9, measured 2026-09-05).
      # MAX on the deepest asset here (2952 bars) serialises 104 KB of JSON into
      # a 190 KB attribute. It is a deliberate click, not the default, and it
      # gzips well — but downsampling it would change what the chart plots, so
      # that stays a design call rather than a silent optimisation.
      DEFAULT_RANGE = "3M"
      # The heading and the query read one value, so the window cannot drift
      # between what the chart says and what it plots.
      PE_CHART_DAYS = 90

      def call(symbol:, range: nil)
        asset = Asset.find_by(symbol: symbol.upcase)
        return Failure([ :not_found, "Asset not found" ]) unless asset

        reading = reading_for(asset)

        if asset.asset_type_fixed_income?
          return Success(reading.merge(
            presenter: nil,
            has_fundamentals: false,
            yield_data: build_yield_data(asset)
          ))
        end

        reading_record = asset.technical_reading
        fundamental = resolve_fundamental(asset)
        presenter = Domain::FundamentalPresenter.new(asset: asset, fundamental: fundamental)

        chart_range = RANGES.key?(range) ? range : DEFAULT_RANGE
        from = RANGES.fetch(chart_range).call
        series = MarketData::Queries::PriceSeries.for(asset)
        price_histories = from ? series.since(from) : series.all

        pe_history = if asset.asset_type_stock?
                       eps = fundamental&.metrics&.dig("eps")&.to_d
                       pe_histories = MarketData::Queries::PriceSeries.for(asset).since(PE_CHART_DAYS.days.ago.to_date)
                       Domain::PeHistoryCalculator.calculate(price_histories: pe_histories, eps: eps)
        end

        dividends = asset.asset_type_stock? || asset.asset_type_etf? ? asset.dividends.order(ex_date: :desc).limit(12) : []
        has_statements = !asset.asset_type_crypto? && asset.financial_statements.exists?
        company_overview = resolve_company_overview(asset)

        Success(reading.merge(
          presenter: presenter,
          has_fundamentals: fundamental.present?,
          has_statements: has_statements,
          price_histories: price_histories,
          chart_range: chart_range,
          pe_history: pe_history,
          dividends: dividends,
          company_overview: company_overview,
          news: Queries::RecentNews.call(asset: asset),
          range_52w: fifty_two_week_range(asset, presenter),
          reading: reading_record,
          signals: Domain::IndicatorSignals.for(reading_record),
          layers: layers_for(asset, reading_record)
        ))
      end

      private

      # ADR-014: the state is derived, the phrase is selected, neither is composed downstream.
      def reading_for(asset)
        observations = asset.technical_observations.recent.within_last(30).limit(5)
        day_change = Domain::DayChange.from_closes(Queries::PriceSeries.for(asset).latest(2).map(&:close))

        {
          asset: asset,
          recent_observations: observations,
          state: Domain::AssetState.for(observations),
          state_source: Domain::AssetState.source(observations),
          day_change: day_change,
          market_context: Queries::AssetMarketContext.call(asset: asset, day_change: day_change)
        }
      end

      # Levels priced off the asset's own daily range. Absent, not empty, when
      # the reading carries no ATR: the levels exist only as far as it does.
      def layers_for(asset, reading)
        atr = reading&.[](:atr)
        return nil if atr.blank?

        {
          atr: atr,
          calculated_at: reading.calculated_at,
          entries: Domain::VolatilityLayers.entries(price: asset.current_price, atr: atr),
          exit: Domain::VolatilityLayers.trailing_exit(highest_high: recent_high(asset), atr: atr)
        }
      end

      # Closed bars only, for the same reason ATR reads them: today's high goes
      # on widening until the session ends.
      def recent_high(asset)
        rows = Queries::PriceSeries.for(asset).latest(Domain::VolatilityLayers::TRAILING_LOOKBACK + 1)
        Queries::PriceSeries.closed_bars(rows).last(Domain::VolatilityLayers::TRAILING_LOOKBACK)
                            .pluck(:high).max
      end

      # The 52-week range is this context's own reading — asset price against two
      # registered metrics — so it is assembled here rather than in the template
      # that used to compute it (X21).
      def fifty_two_week_range(asset, presenter)
        return nil if presenter.blank?

        Domain::FiftyTwoWeekRange.for(
          price: asset.current_price,
          low: presenter.metric("fifty_two_week_low"),
          high: presenter.metric("fifty_two_week_high")
        )
      end

      def build_yield_data(asset)
        days_to_maturity = asset.maturity_date ? (asset.maturity_date - Date.current).to_i : 0
        discount_price = asset.yield_rate ? Domain::YieldCalculator.discount_price(
          face_value: asset.face_value || 10.0,
          annual_yield: asset.yield_rate,
          days: [ days_to_maturity, 0 ].max
        ) : nil

        quantity_example = 100
        total_return = discount_price ? Domain::YieldCalculator.total_return(
          face_value: asset.face_value || 10.0,
          purchase_price: discount_price,
          quantity: quantity_example
        ) : nil

        {
          days_to_maturity: [ days_to_maturity, 0 ].max,
          discount_price: discount_price,
          total_return_100: total_return,
          investment_cost_100: discount_price ? (discount_price * quantity_example).round(2) : nil,
          face_value_100: Domain::YieldCalculator.investment_value(face_value: asset.face_value || 10.0, quantity: quantity_example)
        }
      end

      def resolve_fundamental(asset)
        if asset.asset_type_crypto?
          asset.asset_fundamentals.where(period_label: "CRYPTO_MARKET").latest.first
        else
          calculated = asset.asset_fundamentals.where(period_label: "CALCULATED").latest.first
          calculated || asset.asset_fundamentals.overview.latest.first
        end
      end

      # Read-only "Ficha de empresa" payload — descriptive fields from the
      # Alpha Vantage OVERVIEW row (description, sector, industry, country,
      # exchange, employees, ipo year, website). Returns nil for crypto and
      # fixed_income — those asset types don't have a company behind them and
      # the view renders an alternative copy / nothing.
      def resolve_company_overview(asset)
        return nil if asset.asset_type_crypto? || asset.asset_type_fixed_income?

        overview = asset.asset_fundamentals.overview.latest.first
        overview&.metrics&.with_indifferent_access
      end
    end
  end
end
