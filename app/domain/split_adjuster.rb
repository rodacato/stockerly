# Adjusts positions and historical trades for a stock split.
# Multiplies shares by split ratio and divides avg_cost/price by ratio.
# Uses pessimistic locking on positions for safety.
class SplitAdjuster
  def initialize(stock_split)
    @split = stock_split
    @ratio = stock_split.ratio
  end

  def adjust!
    positions = Position.where(asset: @split.asset)

    positions.find_each do |position|
      position.with_lock do
        position.update!(
          shares: position.shares * @ratio,
          avg_cost: position.avg_cost / @ratio
        )
      end
    end

    adjust_trades!
  end

  private

  def adjust_trades!
    trades = Trade.where(asset: @split.asset)
      .kept
      .where("executed_at < ?", @split.ex_date)

    trades.find_each do |trade|
      trade.update!(
        shares: trade.shares * @ratio,
        price_per_share: trade.price_per_share / @ratio
      )
    end
  end
end
