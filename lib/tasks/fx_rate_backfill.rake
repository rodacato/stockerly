namespace :fx_rate_backfill do
  desc "Fill trades.fx_rate_at_execution for rows where it is NULL (S2-D, #44)"
  task trades: :environment do
    # Idempotent: skip rows already filled. Re-running is safe.
    pending = Trade.where(fx_rate_at_execution: nil).includes(portfolio: :user)
    total = pending.count

    if total.zero?
      puts "fx_rate_backfill:trades — nothing to do (0 rows with NULL fx_rate_at_execution)"
      next
    end

    puts "fx_rate_backfill:trades — processing #{total} trade(s)"

    filled = 0
    skipped = []

    # Cache resolved rates by (from, to) so we don't refresh the gateway repeatedly
    # for trades that share a currency pair (de-dup per the issue's note).
    cache = {}

    pending.find_each do |trade|
      preferred = trade.portfolio.user.preferred_currency
      key = [ trade.currency, preferred ]

      cache[key] ||= Trading::Domain::FxRateResolver.call(
        trade_currency: trade.currency,
        preferred_currency: preferred
      )

      result = cache[key]

      if result.success?
        rate = result.value!
        trade.update_column(:fx_rate_at_execution, rate)
        filled += 1
        source =
          if trade.currency == preferred
            "identity"
          else
            "current_fx_rate"
          end
        puts "  ✓ trade=##{trade.id} #{trade.currency}→#{preferred} " \
             "executed_at=#{trade.executed_at.to_date} " \
             "rate=#{rate.to_s('F')} source=#{source}"
      else
        skipped << { id: trade.id, currency: trade.currency, preferred: preferred, reason: result.failure[1] }
        warn "  ✗ trade=##{trade.id} skipped — #{result.failure[1]}"
      end
    end

    puts ""
    puts "Summary: #{filled} trade(s) updated, #{skipped.size} skipped"

    if skipped.any?
      puts ""
      puts "Skipped trades (left NULL — manual review recommended):"
      skipped.each do |s|
        puts "  - trade=##{s[:id]} #{s[:currency]}→#{s[:preferred]} reason=#{s[:reason]}"
      end
    end
  end
end
