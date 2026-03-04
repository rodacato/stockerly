module Trading
  module Domain
    class ConcentrationAnalyzer
      class << self
        def analyze(portfolio:)
          positions = portfolio.open_positions.includes(:asset)
          return empty_result if positions.empty?

          total_equity = positions.sum { |p| p.shares * (p.asset.current_price || 0) }.to_f
          return empty_result if total_equity.zero?

          position_weights = positions.map do |p|
            value = (p.shares * (p.asset.current_price || 0)).to_f
            { symbol: p.asset.symbol, sector: p.asset.sector, value: value, weight: value / total_equity }
          end

          hhi = (position_weights.sum { |pw| pw[:weight]**2 } * 10_000).round

          max_position = position_weights.max_by { |pw| pw[:weight] }
          max_position_pct = (max_position[:weight] * 100).round(1).to_f

          sector_weights = position_weights
            .group_by { |pw| pw[:sector].presence || "Other" }
            .transform_values { |pws| pws.sum { |pw| pw[:weight] } }
          max_sector = sector_weights.max_by { |_, w| w }
          max_sector_pct = max_sector ? (max_sector.last * 100).round(1).to_f : 0.0

          ConcentrationResult.new(
            hhi: hhi,
            risk_level: determine_risk_level(hhi, max_position_pct, max_sector_pct),
            max_position_symbol: max_position[:symbol],
            max_position_pct: max_position_pct,
            max_sector_name: max_sector&.first || "N/A",
            max_sector_pct: max_sector_pct,
            position_count: positions.size,
            has_data: true
          )
        end

        private

        def determine_risk_level(hhi, max_position_pct, max_sector_pct)
          if hhi > 2500 || max_position_pct > 40 || max_sector_pct > 60
            :high
          elsif hhi > 1500 || max_position_pct > 25 || max_sector_pct > 40
            :moderate
          else
            :low
          end
        end

        def empty_result
          ConcentrationResult.new(
            hhi: 0, risk_level: :low,
            max_position_symbol: "N/A", max_position_pct: 0.0,
            max_sector_name: "N/A", max_sector_pct: 0.0,
            position_count: 0, has_data: false
          )
        end
      end
    end
  end
end
