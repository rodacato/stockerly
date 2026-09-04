module Trading
  module Handlers
    class AdjustPositionsOnSplit
      FACTS = %i[asset_id ex_date ratio_from ratio_to].freeze

      def self.async? = true

      def self.call(event)
        facts = FACTS.index_with { |name| event.is_a?(Hash) ? event[name] : event.public_send(name) }
        # A payload enqueued before the event carried facts has none of them.
        return if facts.each_value.any?(&:blank?)

        Domain::SplitAdjuster.new(**facts).adjust!
      end
    end
  end
end
