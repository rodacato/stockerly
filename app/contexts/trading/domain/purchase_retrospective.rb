module Trading
  module Domain
    # What the buys into a position looked like at the time: how many, at what
    # average price, and what RSI read on those days.
    #
    # It states the facts and stops there. Whether that was good timing is the
    # reader's call — ADR-001 covers describing the past; nothing covers the
    # app grading its owner's decisions.
    class PurchaseRetrospective
      Summary = Data.define(:count, :average_price, :average_rsi, :currency)

      def self.call(position)
        buys = position.trades.kept.select { |trade| trade.side == "buy" }
        return nil if buys.empty?

        shares = buys.sum(&:shares)
        return nil unless shares.positive?

        rsi = average_rsi(position.asset, buys)
        return nil if rsi.nil?

        Summary.new(
          count: buys.size,
          average_price: buys.sum { |t| t.shares * t.price_per_share } / shares,
          average_rsi: rsi,
          currency: position.asset.currency
        )
      end

      # Absent when no buy date has enough history behind it — the block does
      # not appear rather than averaging whatever happened to be recoverable.
      def self.average_rsi(asset, buys)
        readings = MarketData::Queries::RsiOnDates.call(
          asset: asset, dates: buys.map { |trade| trade.executed_at.to_date }
        )
        return nil if readings.empty?

        (readings.values.sum / readings.size).round
      end
      private_class_method :average_rsi
    end
  end
end
