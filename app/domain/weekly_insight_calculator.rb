# Pure stateless calculator for weekly portfolio insights.
# Receives snapshots and positions data, returns observational insight hash.
# No DB reads, no I/O, no side effects. Language is strictly observational.
class WeeklyInsightCalculator
  class << self
    # Main entry point: snapshots + positions → insight hash
    # snapshots: array-like of objects responding to .total_value (ordered oldest→newest)
    # positions: array-like of objects responding to .asset.symbol, .asset.change_percent_24h
    def calculate(snapshots:, positions:)
      return no_data if snapshots.blank? || snapshots.size < 2

      weekly_change = compute_weekly_change(snapshots)
      top = top_performer(positions)
      worst = worst_performer(positions)

      {
        has_data: true,
        weekly_change: weekly_change,
        top_performer: top,
        worst_performer: worst,
        summary_text: build_summary(weekly_change, top)
      }
    end

    private

    def no_data
      { has_data: false, weekly_change: nil, top_performer: nil, worst_performer: nil, summary_text: nil }
    end

    def compute_weekly_change(snapshots)
      oldest = snapshots.first.total_value.to_f
      latest = snapshots.last.total_value.to_f
      return 0.0 if oldest.zero?

      ((latest - oldest) / oldest * 100).round(2)
    end

    def top_performer(positions)
      return nil if positions.blank?

      best = positions.max_by { |p| p.asset.change_percent_24h || 0 }
      return nil unless best&.asset&.change_percent_24h

      { symbol: best.asset.symbol, change: best.asset.change_percent_24h.to_f.round(2) }
    end

    def worst_performer(positions)
      return nil if positions.blank?

      worst = positions.min_by { |p| p.asset.change_percent_24h || 0 }
      return nil unless worst&.asset&.change_percent_24h

      { symbol: worst.asset.symbol, change: worst.asset.change_percent_24h.to_f.round(2) }
    end

    def build_summary(weekly_change, top)
      direction = weekly_change >= 0 ? "up" : "down"
      text = "Your portfolio was #{direction} #{weekly_change.abs}% this week."
      text += " Top performer: #{top[:symbol]} (#{format_change(top[:change])})." if top
      text
    end

    def format_change(value)
      value >= 0 ? "+#{value}%" : "#{value}%"
    end
  end
end
