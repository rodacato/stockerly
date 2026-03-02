class RiskMetrics < Dry::Struct
  attribute :volatility, Types::Float
  attribute :sharpe_ratio, Types::Float
  attribute :max_drawdown, Types::Float
  attribute :has_sufficient_data, Types::Bool

  def high_volatility?
    volatility > 0.25
  end

  def low_volatility?
    volatility < 0.10
  end

  def sharpe_label
    case sharpe_ratio
    when Float::INFINITY then "N/A"
    when 1.0..Float::INFINITY then "Good"
    when 0.5...1.0 then "Acceptable"
    when 0.0...0.5 then "Low"
    else "Negative"
    end
  end
end
