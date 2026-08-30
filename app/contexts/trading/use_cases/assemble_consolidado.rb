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
      CETES_TERM = "28"

      def call(user:, period: nil)
        portfolio = user.portfolio
        currency  = user.preferred_currency
        period    = PERIODS.key?(period) ? period : DEFAULT_PERIOD

        return empty(currency, period) unless portfolio

        from = starts_on(portfolio, period)
        fx = Domain::FxDegradation.new

        summary = fx.figure { Domain::PortfolioSummary.prewarmed(portfolio, currency: currency) }
        twr = fx.figure { Domain::TimeWeightedReturn.new(portfolio, currency: currency).between(from: from) }

        {
          period: period,
          from: from,
          currency: currency,
          summary: summary,
          series: fx.figure([]) { series_for(portfolio, currency, from) },
          twr: twr,
          vs_cetes: twr && vs_cetes(twr, from),
          vs_hold: twr && fx.figure { vs_hold(portfolio, currency, from, twr) },
          allocation: fx.figure({}) { allocation_for(portfolio, currency) },
          fx_unavailable: fx.degraded?
        }
      end

      private

      def allocation_for(portfolio, currency)
        portfolio.allocation_by_asset_type(currency: currency)
      end

      def empty(currency, period)
        { period: period, from: Date.current, currency: currency, summary: nil, fx_unavailable: false,
          series: [], twr: nil, vs_cetes: nil, vs_hold: nil, allocation: {} }
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

      def vs_cetes(mine, from)
        theirs = MarketData::Queries::CetesReinvestedReturn.call(term: CETES_TERM, from: from, to: Date.current)
        return nil if theirs.nil?

        { points: mine - theirs, mine: mine, benchmark: theirs, term: CETES_TERM }
      end

      # The counterfactual: the positions held at the start of the period,
      # valued at today's prices. Nil when there were none — there is nothing
      # to have held.
      def vs_hold(portfolio, currency, from, mine)
        valuation = Domain::HistoricalValuation.new(portfolio, currency: currency)
        opening = valuation.invested_on(from)
        return nil unless opening.positive?

        held_today = value_today(portfolio, currency, valuation.shares_on(from))
        hold_return = ((held_today - opening) / opening * 100).to_f

        { points: mine - hold_return, mine: mine, hold_return: hold_return, hold_value: held_today.to_f }
      end

      def value_today(portfolio, currency, held)
        held.sum do |asset, shares|
          portfolio.convert(shares * (asset.current_price || 0), from: asset.currency, to: currency)
        end
      end
    end
  end
end
