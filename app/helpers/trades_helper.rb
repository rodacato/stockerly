module TradesHelper
  # Single-pass aggregation of a trades collection by currency.
  # Returns { buys: { currency => total }, sells: { currency => total },
  # fees: { currency => total } }. Keeps the view template focused on
  # presentation by moving the multiple-iteration group_by/sum logic here.
  def trades_summary_by_currency(trades)
    summary = {
      buys:  Hash.new(0),
      sells: Hash.new(0),
      fees:  Hash.new(0)
    }

    trades.each do |trade|
      bucket = trade.buy? ? :buys : :sells
      summary[bucket][trade.currency] += trade.total_amount
      summary[:fees][trade.currency] += trade.fee if trade.fee.positive?
    end

    summary
  end
end
