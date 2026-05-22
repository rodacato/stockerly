module TradesHelper
  # Single-pass aggregation of a trades collection by currency.
  # Returns { buys: { currency => total }, sells: { currency => total },
  # fees: { currency => total }, count: Integer, realized: { currency => total } }.
  #
  # Realized cash flow is computed as a *gross sell minus matched buy
  # cost* per side trade — using the trade's own avg-cost via the linked
  # position when present. This is an approximation: positions store the
  # *current* avg cost, not the historical avg cost at the moment of the
  # sell, so multi-sale histories will drift. The number is still useful
  # as an order-of-magnitude indicator of realized P/L and is what the
  # Stockerly-2.0 mockup footer row is illustrating; an exact realized
  # P/L would require per-trade snapshot of avg_cost which the schema
  # does not yet carry. Flagged in PR body of #145.
  def trades_summary_by_currency(trades)
    summary = {
      buys:     Hash.new(0),
      sells:    Hash.new(0),
      fees:     Hash.new(0),
      realized: Hash.new(0),
      count:    0
    }

    trades.each do |trade|
      summary[:count] += 1
      bucket = trade.buy? ? :buys : :sells
      summary[bucket][trade.currency] += trade.total_amount
      # Safe-nav on `fee` — the DB column carries a 0.0 default + null:false,
      # but in-memory unsaved records or unrelated edge cases can leave it
      # nil, and crashing the page over a missing fee is worse than zero.
      summary[:fees][trade.currency] += trade.fee if trade.fee&.positive?

      if trade.sell? && trade.position.present?
        cost_basis = trade.position.avg_cost * trade.shares
        summary[:realized][trade.currency] += trade.total_amount - cost_basis - (trade.fee || 0)
      end
    end

    summary
  end
end
