class AdjustPositionsOnSplit
  def self.async? = true

  def self.call(event)
    split_id = event.is_a?(Hash) ? event[:stock_split_id] : event.stock_split_id
    split = StockSplit.find_by(id: split_id)
    return unless split

    SplitAdjuster.new(split).adjust!
  end
end
