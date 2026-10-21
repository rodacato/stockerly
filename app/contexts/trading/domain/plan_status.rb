module Trading
  module Domain
    # How what the owner holds compares with the plan they wrote: each share
    # against its target, and whether this month's contribution has happened.
    # It reports; it never says what to buy.
    class PlanStatus
      GAP_POINTS = 8
      CONTRIBUTION_DUE_DAY = 10
      KINDS = {
        stocks_share: %w[stock etf],
        crypto_share: %w[crypto],
        fixed_income_share: %w[fixed_income]
      }.freeze

      Share = Data.define(:key, :actual, :target) do
        def gap = actual - target
        def off? = gap.abs >= GAP_POINTS
      end

      Status = Data.define(:shares, :planned, :contributed, :due) do
        def off_shares = shares.select(&:off?)
        def contribution_missing? = due && planned.positive? && !contributed.nil? && !contributed.positive?
      end

      # `allocation` is value per asset type, in any one currency; `contributed`
      # is net capital added this month in MXN, or nil when it could not be valued.
      def self.call(plan:, allocation:, contributed:, today: Date.current)
        Status.new(
          shares: shares_for(plan, allocation),
          planned: plan.monthly_contribution,
          contributed: contributed,
          due: today.day >= CONTRIBUTION_DUE_DAY
        )
      end

      def self.shares_for(plan, allocation)
        values = KINDS.transform_values { |types| types.sum { |type| allocation.fetch(type, 0) } }
        total = values.values.sum
        return [] unless total.positive?

        KINDS.keys.map do |key|
          Share.new(key: key, actual: (values[key] / total * 100).round, target: plan.public_send(key))
        end
      end
      private_class_method :shares_for
    end
  end
end
