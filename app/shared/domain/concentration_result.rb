class ConcentrationResult < Dry::Struct
  attribute :hhi, Types::Integer
  attribute :risk_level, Types::Symbol.enum(:low, :moderate, :high)
  attribute :max_position_symbol, Types::String
  attribute :max_position_pct, Types::Float
  attribute :max_sector_name, Types::String
  attribute :max_sector_pct, Types::Float
  attribute :position_count, Types::Integer
  attribute :has_data, Types::Bool

  def high_risk?
    risk_level == :high
  end

  def moderate_risk?
    risk_level == :moderate
  end

  def low_risk?
    risk_level == :low
  end

  def hhi_label
    case hhi
    when 0..1499 then "Diversified"
    when 1500..2499 then "Moderate"
    else "Concentrated"
    end
  end
end
