module Trading
  module UseCases
    # The `vs. tu plan` block's readings: the price against what you paid, and
    # against the threshold you asked to be told about. Composed from what the
    # controller already loaded — this issues no query, and crosses no boundary
    # the controller had not already crossed to hand it these arguments.
    #
    # X21: the template used to assemble this. A layer that should be rendering
    # was deciding what to render, which is CKP-7's objection one layer out.
    class LoadAssetAnchors < SimpleUseCase
      def call(asset:, position_data:, rules:)
        threshold = threshold_rule(rules)

        {
          cost: cost_anchor(asset, position_data),
          threshold: threshold_anchor(asset, threshold),
          threshold_rule: threshold,
          other_rules: Array(rules) - [ threshold ].compact
        }
      end

      private

      def cost_anchor(asset, position_data)
        position = position_data && position_data[:position]
        return nil unless position

        Domain::PriceAnchor.against_cost(price: asset.current_price, cost: position.avg_cost)
      end

      # The rule whose threshold_value is a price, so the only kind a quote may
      # be compared against (AlertRule::PRICE_THRESHOLD_CONDITIONS).
      def threshold_rule(rules)
        Array(rules).find { |rule| rule.active? && AlertRule::PRICE_THRESHOLD_CONDITIONS.include?(rule.condition) }
      end

      def threshold_anchor(asset, rule)
        return nil unless rule

        Domain::PriceAnchor.against_threshold(price: asset.current_price, threshold: rule.threshold_value)
      end
    end
  end
end
