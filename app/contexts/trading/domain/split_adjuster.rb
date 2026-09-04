# Adjusts positions and historical trades for a stock split.
# Multiplies shares by split ratio and divides avg_cost/price by ratio.
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
          adjust_positions!
          adjust_trades!
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

      def adjust_positions!
        Position.where(asset_id: @asset_id).find_each do |position|
          position.update!(
            shares: position.shares * @ratio,
            avg_cost: position.avg_cost / @ratio
          )
        end
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
    end
  end
end
