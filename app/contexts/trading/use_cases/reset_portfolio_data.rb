module Trading
  module UseCases
    # Deletes everything that descends from a trade, so a re-import starts from
    # nothing rather than merging into half a history.
    #
    # The catalogue, the FX rates, the price history and the portfolio row are
    # deliberately left alone: none of them is derived from a trade, and all of
    # them cost provider calls to rebuild. That is the whole reason this exists
    # instead of `db:reset`.
    class ResetPortfolioData < SimpleUseCase
      TABLES = %i[trades positions snapshots dividend_payments].freeze

      def self.counts(portfolio)
        TABLES.index_with { |table| portfolio.public_send(table).count }
      end

      def call(portfolio:)
        counts = self.class.counts(portfolio)

        ActiveRecord::Base.transaction do
          # Trades first: a position destroys its own trades on the way out, and
          # letting it do that mid-sweep leaves the trades relation counting rows
          # that are already gone.
          portfolio.trades.destroy_all
          portfolio.positions.destroy_all
          portfolio.snapshots.destroy_all
          portfolio.dividend_payments.destroy_all

          # Back to nil so the next import backdates it to its own earliest
          # trade; left as it is, RebuildSnapshots clamps to the old first trade
          # and silently drops every snapshot before it.
          portfolio.update!(inception_date: nil)
        end

        counts
      end
    end
  end
end
