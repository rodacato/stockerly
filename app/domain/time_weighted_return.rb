class TimeWeightedReturn
  # Calculates Time-Weighted Return (TWR) from a series of snapshots.
  # TWR = Product(1 + R_i) - 1, where R_i is the return for each sub-period.
  # Cash flows are detected from changes in invested_value between snapshots.
  #
  # Input:
  #   snapshots: array of objects responding to #date, #total_value, #invested_value
  # Output:
  #   GainLoss value object with absolute and percent fields

  def initialize(snapshots:)
    @snapshots = snapshots.sort_by(&:date)
  end

  def calculate
    return zero_result if @snapshots.size < 2

    sub_period_returns = compute_sub_period_returns
    return zero_result if sub_period_returns.empty?

    cumulative = sub_period_returns.reduce(1.0) { |product, r| product * (1 + r) }
    percent = (cumulative - 1) * 100
    absolute = @snapshots.last.total_value.to_f - @snapshots.first.total_value.to_f

    GainLoss.new(absolute: absolute.round(2), percent: percent.round(2))
  end

  def annualized
    result = calculate
    return zero_result if result.zero?

    days = (@snapshots.last.date - @snapshots.first.date).to_f
    return result if days <= 0

    twr_decimal = result.percent / 100.0
    annualized_decimal = (1 + twr_decimal)**(365.0 / days) - 1
    annualized_percent = annualized_decimal * 100

    GainLoss.new(absolute: result.absolute, percent: annualized_percent.round(2))
  end

  private

  def compute_sub_period_returns
    @snapshots.each_cons(2).map do |prev, curr|
      v_start = prev.total_value.to_f
      v_end = curr.total_value.to_f
      cash_flow = detect_cash_flow(prev, curr)

      next 0.0 if v_start.zero?

      (v_end - v_start - cash_flow) / v_start
    end
  end

  def detect_cash_flow(prev_snapshot, curr_snapshot)
    return 0.0 unless prev_snapshot.respond_to?(:invested_value) && curr_snapshot.respond_to?(:invested_value)
    return 0.0 if prev_snapshot.invested_value.nil? || curr_snapshot.invested_value.nil?

    curr_snapshot.invested_value.to_f - prev_snapshot.invested_value.to_f
  end

  def zero_result
    GainLoss.new(absolute: 0.0, percent: 0.0)
  end
end
