module Trading
  module UseCases
    # The "Mi posición" side of the asset detail: what you hold of this asset,
    # split by what moved it, and what your buys looked like at the time.
    # Returns nil when you hold none — the tab does not exist then.
    class LoadAssetPosition < SimpleUseCase
      def call(user:, asset:)
        portfolio = user.portfolio
        return nil unless portfolio

        position = portfolio.open_positions.includes(:asset, :trades).find_by(asset_id: asset.id)
        return nil unless position

        currency = user.preferred_currency

        {
          position: position,
          currency: currency,
          breakdown: breakdown_for(position, currency),
          retrospective: Domain::PurchaseRetrospective.call(position),
          trades: position.trades.kept.order(executed_at: :desc).limit(5)
        }
      end

      private

      # A missing rate makes the split impossible, not the tab: the shares,
      # the average cost and the operations are all still true.
      def breakdown_for(position, currency)
        breakdown = Domain::PositionBreakdown.new(position, currency: currency)
        breakdown.total
        breakdown
      rescue Trading::Domain::MissingFxRate
        nil
      end
    end
  end
end
