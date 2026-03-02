module Trading
  module Handlers
    class RecalculateAvgCostOnTrade
      def self.call(event)
        position_id = event.is_a?(Hash) ? event[:position_id] : event.position_id

        position = Position.find_by(id: position_id)
        return unless position

        position.with_lock do
          position.recalculate_avg_cost!
        end
      end
    end
  end
end
