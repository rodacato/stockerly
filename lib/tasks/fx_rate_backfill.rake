namespace :fx_rate_backfill do
  desc "Fill trades.fx_rate_at_execution (against MXN, at each trade's own date) where NULL"
  task trades: :environment do
    # Idempotent: skip rows already filled. Re-running is safe.
    pending = Trade.where(fx_rate_at_execution: nil)
    total = pending.count

    if total.zero?
      puts "fx_rate_backfill:trades — nothing to do (0 rows with NULL fx_rate_at_execution)"
      next
    end

    reference = Trading::Domain::ExecutionRate::REFERENCE
    puts "fx_rate_backfill:trades — processing #{total} trade(s) against #{reference}"

    filled = 0
    skipped = []

    pending.find_each do |trade|
      executed_on = trade.executed_at.to_date
      rate = Trading::Domain::ExecutionRate.capture(currency: trade.currency, at_date: executed_on)

      if rate
        trade.update_column(:fx_rate_at_execution, rate)
        filled += 1
        puts "  ✓ trade=##{trade.id} #{trade.currency}→#{reference} executed_at=#{executed_on} rate=#{rate.to_s('F')}"
      else
        skipped << { id: trade.id, currency: trade.currency, date: executed_on }
        warn "  ✗ trade=##{trade.id} skipped — no #{trade.currency}→#{reference} rate on #{executed_on}"
      end
    end

    puts ""
    puts "Summary: #{filled} trade(s) updated, #{skipped.size} skipped"

    if skipped.any?
      puts ""
      puts "Skipped trades (left NULL — manual review recommended):"
      skipped.each do |s|
        puts "  - trade=##{s[:id]} #{s[:currency]} on #{s[:date]}"
      end
    end
  end
end
