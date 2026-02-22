class RecalculateAvgCostOnTrade
  def self.call(event)
    position_id = event.is_a?(Hash) ? event[:position_id] : event.position_id

    position = Position.find_by(id: position_id)
    position&.recalculate_avg_cost!
  end
end
