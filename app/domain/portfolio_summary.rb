class PortfolioSummary
  attr_reader :portfolio

  def initialize(portfolio)
    @portfolio = portfolio
  end

  def total_value
    portfolio.total_value
  end

  def buying_power
    portfolio.buying_power
  end

  def unrealized_gain
    gain = portfolio.total_unrealized_gain
    base = total_invested
    percent = base.positive? ? (gain / base * 100) : 0.0
    GainLoss.new(absolute: gain.to_f, percent: percent.to_f)
  end

  def day_gain
    yesterday = portfolio.yesterday_snapshot
    return GainLoss.new(absolute: 0.0, percent: 0.0) unless yesterday

    diff = total_value - yesterday.total_value
    percent = yesterday.total_value.positive? ? (diff / yesterday.total_value * 100) : 0.0
    GainLoss.new(absolute: diff.to_f, percent: percent.to_f)
  end

  def domestic_value
    portfolio.open_positions.domestic.sum { |p| p.market_value }
  end

  def international_value
    portfolio.open_positions.international.sum { |p| p.market_value }
  end

  def total_invested
    portfolio.open_positions.sum { |p| p.shares * p.avg_cost }
  end

  def to_h
    {
      total_value: total_value,
      buying_power: buying_power,
      unrealized_gain: unrealized_gain,
      day_gain: day_gain,
      domestic_value: domestic_value,
      international_value: international_value,
      total_invested: total_invested
    }
  end
end
