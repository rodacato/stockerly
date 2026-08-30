# Adjusts positions and historical trades for a stock split.
# Multiplies shares by split ratio and divides avg_cost/price by ratio.
module Trading
  module Domain
    class SplitAdjuster
      def initialize(stock_split)
        @split = stock_split
        @ratio = stock_split.ratio
      end

      # Locking the split makes the already-applied check and the write atomic,
      # and Mission Control's retry button reaches this handler.
      def adjust!
        @split.with_lock do
          return if @split.applied_at?

          adjust_positions!
          adjust_trades!
          @split.update!(applied_at: Time.current)
        end
      end

      private

      def adjust_positions!
        Position.where(asset: @split.asset).find_each do |position|
          position.update!(
            shares: position.shares * @ratio,
            avg_cost: position.avg_cost / @ratio
          )
        end
      end

      def adjust_trades!
        Trade.where(asset: @split.asset)
          .kept
          .where("executed_at < ?", @split.ex_date)
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
