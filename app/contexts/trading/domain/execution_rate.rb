module Trading
  module Domain
    # Turns a trade's stored `fx_rate_at_execution` into the multiplier that
    # states that trade's money in an arbitrary currency.
    #
    # The column means ONE thing: how many REFERENCE units one unit of the
    # trade's currency bought on the day it executed. It used to mean "in
    # whatever the user preferred when the row was written", which made it wrong
    # the moment that preference changed and unrepairable afterwards — the
    # backfill only ever filled NULLs.
    #
    #   amount_in(target) = shares × price × (stored ÷ target→REFERENCE on that day)
    #
    # Both conversions are dated to the execution, so a peso gain earned at
    # 17.20 does not become a different number because today's rate is 18.40.
    class ExecutionRate
      REFERENCE = "MXN".freeze

      def self.multiplier(trade:, target:)
        target = target.to_s.upcase
        # Same currency cancels the ratio exactly; skipping the lookup is both
        # the correct answer and the hot path.
        return BigDecimal(1) if target == trade.currency

        stored = trade.fx_rate_at_execution
        raise MissingFxRate, "Trade##{trade.id}: no fx_rate_at_execution; cannot state its value in #{target}" if stored.nil?
        return stored if target == REFERENCE

        divisor = FxRateHistory.rate_on(base: target, quote: REFERENCE, date: trade.executed_at.to_date)
        raise MissingFxRate, "No #{target}->#{REFERENCE} rate on #{trade.executed_at.to_date}; cannot state Trade##{trade.id} in #{target}" unless divisor&.positive?

        stored / divisor
      end

      # The rate to capture for a trade: its currency against the reference, on
      # the day it executed. `override` is what the user typed, and it means the
      # same thing the column does.
      def self.capture(currency:, at_date:, override: nil)
        currency = currency.to_s.upcase
        return BigDecimal(1) if currency == REFERENCE
        return override if override

        FxRateHistory.rate_on(base: currency, quote: REFERENCE, date: at_date || Date.current)
      end
    end
  end
end
