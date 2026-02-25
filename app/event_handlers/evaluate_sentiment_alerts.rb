class EvaluateSentimentAlerts
  def self.async? = true

  def self.call(event)
    index_type = event.is_a?(Hash) ? event[:index_type] : event.index_type
    value      = event.is_a?(Hash) ? event[:value] : event.value

    Alerts::EvaluateSentimentRules.new.call(index_type: index_type, value: value)
  end
end
