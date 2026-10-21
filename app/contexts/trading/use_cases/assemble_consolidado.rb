module Trading
  module UseCases
    # The Consolidado (slice 4): what the patrimony is worth, how it got there,
    # and whether moving it beat leaving it alone.
    #
    # Every figure that makes a claim uses TWR (D12). The money-weighted
    # PeriodReturnsCalculator lost its last production caller when Historial
    # replaced /positions, and is kept deliberately: `time_weighted_return_spec`
    # contrasts the two to prove D12's claim, so it is the executable form of
    # the argument rather than leftover code.
    class AssembleConsolidado < SimpleUseCase
      PERIODS = {
        "1M"  => -> { 1.month.ago.to_date },
        "3M"  => -> { 3.months.ago.to_date },
        "1A"  => -> { 1.year.ago.to_date },
        "YTD" => -> { Date.current.beginning_of_year },
        "MAX" => -> { nil }
      }.freeze

      DEFAULT_PERIOD = "1A"

      def call(user:, period: nil, by: nil)
        portfolio = user.portfolio
        currency  = user.preferred_currency
        period    = PERIODS.key?(period) ? period : DEFAULT_PERIOD

        return empty(currency, period) unless portfolio

        from = starts_on(portfolio, period)
        dates = portfolio.snapshots.where(date: from..Date.current).order(:date).pluck(:date)
        from = dates.first || from
        to = dates.last || Date.current
        fx = Domain::FxDegradation.new

        summary = fx.figure { Domain::PortfolioSummary.prewarmed(portfolio, currency: currency) }
        twr = fx.figure { Domain::TimeWeightedReturn.new(portfolio, currency: currency).between(from: from, to: to) }

        {
          period: period,
          from: from,
          to: to,
          currency: currency,
          summary: summary,
          series: fx.figure([]) { series_for(portfolio, currency, from) },
          twr: twr,
          vs_cetes: twr && currency == "MXN" ? Domain::CetesComparison.between(twr, from, to) : nil,
          vs_index: twr && currency == "MXN" ? Domain::IndexComparison.between(twr, from, to) : nil,
          vs_hold: twr && fx.figure { vs_hold(portfolio, currency, from, to, twr) },
          allocation: fx.figure({}) { allocation_for(portfolio, currency, by) },
          currency_exposure: currency == "MXN" ? fx.figure { currency_exposure(portfolio, summary) } : nil,
          fx_unavailable: fx.degraded?,
          prices_unavailable: fx.prices_unavailable?
        }
      end

      private

      def allocation_for(portfolio, currency, by)
        return sector_allocation(portfolio, currency) if by == "sector"

        portfolio.allocation_by_asset_type(currency: currency)
      end

      # Over quotes that are not current the share would be stale, so it is absent.
      def currency_exposure(portfolio, summary)
        return nil unless summary&.quotes_current?

        Domain::CurrencyExposure.call(by_currency: portfolio.allocation_by_currency(currency: "MXN"))
      end

      # A stock reads as its sector; what has none reads as what it is (ETF,
      # Cripto, Renta fija) rather than as missing data.
      def sector_allocation(portfolio, currency)
        sectors = MarketData::Queries::AssetSectors.call(assets: portfolio.open_positions.includes(:asset).map(&:asset))
        portfolio.allocation_by_sector(
          currency: currency,
          sector_of: ->(asset) { sectors[asset.id] || (asset.asset_type.to_sym unless asset.asset_type_stock?) }
        )
      end

      def empty(currency, period)
        { period: period, from: Date.current, to: Date.current, currency: currency, summary: nil, fx_unavailable: false, prices_unavailable: false,
          series: [], twr: nil, vs_cetes: nil, vs_hold: nil, vs_index: nil, allocation: {}, currency_exposure: nil }
      end

      def starts_on(portfolio, period)
        boundary = PERIODS.fetch(period).call
        inception = portfolio.inception_date || portfolio.snapshots.minimum(:date) || Date.current
        boundary ? [ boundary, inception ].max : inception
      end

      # Same degradation as every other screen: a missing rate makes the
      # consolidation impossible, not the page.

      # Two lines that start together and separate by exactly the return: the
      # portfolio's value, and the capital that was put into it.
      def series_for(portfolio, currency, from)
        snapshots = portfolio.snapshots.where(date: from..Date.current).order(:date).to_a
        return [] if snapshots.size < 2

        flows = Domain::ExternalFlows.new(portfolio, currency: currency)
                                     .by_date(snapshots.first.date..snapshots.last.date)
        contributed = value_of(portfolio, currency, snapshots.first)

        snapshots.map do |snapshot|
          contributed += flows[snapshot.date] unless snapshot == snapshots.first
          { date: snapshot.date, value: value_of(portfolio, currency, snapshot).to_f, contributed: contributed.to_f }
        end
      end

      def value_of(portfolio, currency, snapshot)
        portfolio.convert(snapshot.total_value, from: snapshot.currency, to: currency, at_date: snapshot.date)
      end

      # The counterfactual: the positions held at the start of the period,
      # valued at the last snapshot's date. Nil when there were none — there is nothing
      # to have held.
      def vs_hold(portfolio, currency, from, to, mine)
        valuation = Domain::HistoricalValuation.new(portfolio, currency: currency)
        opening = valuation.market_value_on(from)
        return nil unless opening.positive?

        held_value = valuation.value_of_holdings_on(valuation.shares_on(from), to)
        hold_return = ((held_value - opening) / opening * 100).to_f

        { points: mine - hold_return, mine: mine, hold_return: hold_return, hold_value: held_value.to_f }
      end
    end
  end
end
