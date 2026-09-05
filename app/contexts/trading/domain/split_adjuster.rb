# Adjusts positions and historical trades for a stock split.
# Trades are rewritten into post-split terms; positions are re-derived from them.
module Trading
  module Domain
    class SplitAdjuster
      def initialize(asset_id:, ex_date:, ratio_from:, ratio_to:)
        @asset_id = asset_id
        @ex_date = ex_date.to_date
        @ratio_from = ratio_from
        @ratio_to = ratio_to
        @ratio = ratio_to.to_f / ratio_from
      end

      # The adjustment is recorded first: its unique index is what makes a
      # Mission Control retry a no-op, and it rolls back with the rewrites.
      def adjust!
        SplitAdjustment.transaction do
          record_adjustment!
          adjust_trades!
          adjust_positions!
        end
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      private

      def record_adjustment!
        SplitAdjustment.create!(
          asset_id: @asset_id, ex_date: @ex_date,
          ratio_from: @ratio_from, ratio_to: @ratio_to
        )
      end

      def adjust_trades!
        Trade.where(asset_id: @asset_id)
          .kept
          .where(executed_at: ...@ex_date)
          .find_each do |trade|
            trade.update!(
              shares: trade.shares * @ratio,
              price_per_share: trade.price_per_share / @ratio
            )
          end
      end

      # The row lock is what makes two splits landing at once compose instead of
      # overwriting each other: the second waits, then re-reads what the first left.
      def adjust_positions!
        Position.where(asset_id: @asset_id).find_each do |position|
          position.with_lock { rewrite(position) }
        end
      end

      # A split neither buys nor sells, so the position's lifecycle is not its
      # business — only the numbers the rewritten trades now imply.
      def rewrite(position)
        return scale(position) if position.trades.kept.empty?

        position.recalculate_avg_cost!
        position.update!(shares: position.shares_from_trades)
      end

      # Shares entered without a trade history have nothing to re-derive from, so
      # they are scaled — but only when they were held before the split happened.
      def scale(position)
        return unless position.opened_at&.to_date&.< @ex_date

        position.update!(
          shares: position.shares * @ratio,
          avg_cost: position.avg_cost / @ratio
        )
      end
    end
  end
end
