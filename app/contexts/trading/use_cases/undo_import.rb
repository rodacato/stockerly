module Trading
  module UseCases
    # Removes an imported batch by the broker ids it carried. Destroys rather
    # than discards so the same confirmation can be imported again — the
    # external_id index is unique and a discarded row still holds its id.
    #
    # Exists because imported trades are born outside the 30-day modification
    # window (they are dated when they executed, not when they were captured),
    # so the UI cannot undo them and a console `destroy_all` would skip the
    # recalculation that keeps positions honest.
    class UndoImport < SimpleUseCase
      def call(portfolio:, external_ids:)
        trades = portfolio.trades.where(external_id: external_ids)
        return { removed: 0 } if trades.empty?

        earliest = trades.minimum(:executed_at).to_date
        positions = Position.where(id: trades.distinct.pluck(:position_id).compact)

        removed = trades.destroy_all.size
        positions.each { |position| settle(position) }
        Trading::UseCases::RebuildSnapshots.call(portfolio: portfolio, from: earliest)

        { removed: removed, positions_closed: positions.count(&:destroyed?), from: earliest }
      end

      private

      def settle(position)
        remaining = position.trades.kept.buys.sum(:shares) - position.trades.kept.sells.sum(:shares)
        return position.destroy if remaining <= 0

        position.update!(shares: remaining)
        position.recalculate_avg_cost!
      end
    end
  end
end
