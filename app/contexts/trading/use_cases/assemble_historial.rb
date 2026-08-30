module Trading
  module UseCases
    # The three lists that have no other home (D43): the trade log, the
    # dividends received, and what closed positions actually made.
    #
    # No `tab:` parameter — the screen stacks all three in one scroll, which is
    # what #294 chose for the asset detail's sub-tabs and the Bandeja does with
    # its date groups. `Posiciones abiertas` is deliberately absent: it
    # duplicated Holdings, and is the likeliest reason nobody ever linked here.
    class AssembleHistorial < ApplicationUseCase
      TRADE_LIMIT = 50

      def call(user:)
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        currency = user.preferred_currency

        Success({
          currency: currency,
          trades: portfolio.trades.kept.recent.includes(:asset, :position).limit(TRADE_LIMIT),
          dividends: portfolio.dividend_payments.recent.includes(dividend: :asset),
          closed: closed_with_gain(Domain::FxDegradation.new, portfolio, currency)
        })
      end

      private

      # The gain is computed here rather than in the view so a missing FX rate
      # surfaces as one failure for the section, not as an exception halfway
      # through rendering a list.
      def closed_with_gain(fx, portfolio, currency)
        portfolio.closed_positions.includes(:asset, :trades).map do |position|
          gain = fx.figure { Domain::RealizedGain.new(position, currency: currency).amount }
          { position: position, gain: gain }
        end
      end
    end
  end
end
