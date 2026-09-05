module Trading
  module Domain
    # What one position made or lost over a window, in money (#611).
    #
    # Money-weighted on purpose, and it is the opposite call from D12's. That
    # decision chose time-weighted for the portfolio because the screen it
    # feeds compares against CETES, and a deposit must not read as performance.
    # This block compares against nothing: the question is "how many pesos did
    # this position make me since Friday", and the honest answer to that counts
    # the pesos. What it must not do is count money you *added* as money it
    # earned — so the flows come out, and only the flows.
    class PositionReturns
      Window = Data.define(:key, :amount, :percent)

      # No `Total`. The artboard drew one, and `Tu posición` already is one —
      # a second copy of the same number on the same screen is not a window
      # (D95). These five are the ones that did not exist.
      WINDOWS = {
        "1D" => -> { 1.day.ago.to_date },
        "1S" => -> { 1.week.ago.to_date },
        "1M" => -> { 1.month.ago.to_date },
        "3M" => -> { 3.months.ago.to_date },
        "1A" => -> { 1.year.ago.to_date }
      }.freeze

      # ADR-0023: a screen that converts without an FxDegradation is the defect
      # that guard exists to prevent. Every figure here crosses currencies, so
      # a missing rate makes the window absent and the screen able to say why —
      # it must never take the asset detail down with it.
      def initialize(portfolio, asset, currency:, degradation: FxDegradation.new)
        @asset       = asset
        @degradation = degradation
        @valuation   = HistoricalValuation.new(portfolio, currency: currency)
        @flows       = ExternalFlows.new(portfolio, currency: currency, asset: asset)
      end

      delegate :degraded?, to: :@degradation

      def windows
        @windows ||= begin
          current = value_on(Date.current)
          current.nil? ? [] : WINDOWS.filter_map { |key, from| window(key, from.call, current) }
        end
      end

      private

      # Absent, not zero, when the window opens before the position did: not
      # having owned it yet is a different answer from not having moved, the
      # same distinction DayChange draws for a newly tracked asset.
      def window(key, from, current)
        opened = value_on(from)
        return nil if opened.nil?

        # from + 1: a trade executed on the opening day is already inside the
        # value read for that day, so counting it again would remove it twice.
        contributed = @degradation.figure { @flows.between(from + 1, Date.current) }
        return nil if contributed.nil?

        amount = current - opened - contributed
        base = opened + contributed

        Window.new(key: key, amount: amount, percent: percent_of(amount, base))
      end

      def percent_of(amount, base)
        return nil unless base.positive?

        amount / base * 100
      end

      def value_on(date)
        @degradation.figure { @valuation.asset_value_on(@asset, date) }
      end
    end
  end
end
