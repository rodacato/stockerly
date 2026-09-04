class GainLoss < Dry::Struct
  attribute :absolute, Types::Float
  attribute :percent, Types::Float

  def positive?
    absolute > 0
  end

  def negative?
    absolute < 0
  end

  delegate :zero?, to: :absolute

  def to_s
    sign = positive? ? "+" : ""
    "#{sign}#{absolute.round(2)} (#{sign}#{percent.round(2)}%)"
  end
end
