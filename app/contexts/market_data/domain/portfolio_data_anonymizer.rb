module MarketData
  module Domain
    # Extracts only percentage-based, anonymized data from portfolio context.
    # Never includes dollar amounts, PII, or account information.
    class PortfolioDataAnonymizer
      def self.anonymize(portfolio:, summary:, concentration:)
        {
          weekly_change: summary&.dig(:weekly_change)&.round(2),
          top_performer: extract_performer(summary, :top),
          worst_performer: extract_performer(summary, :worst),
          position_count: portfolio.positions.open.count,
          concentration_hhi: concentration.respond_to?(:hhi) ? concentration.hhi : concentration&.dig(:hhi),
          risk_level: concentration.respond_to?(:hhi_label) ? concentration.hhi_label : concentration&.dig(:label),
          sector_weights: extract_sector_weights(portfolio)
        }
      end

      def self.extract_performer(summary, type)
        key = type == :top ? :top_performer : :worst_performer
        performer = summary&.dig(key)
        return nil unless performer

        { symbol: performer[:symbol], change_percent: performer[:change_percent]&.round(2) }
      end

      def self.extract_sector_weights(portfolio)
        positions = portfolio.positions.open.includes(:asset)
        return {} if positions.empty?

        total = positions.sum { |p| p.shares * (p.asset.current_price || 0) }
        return {} if total.zero?

        positions.group_by { |p| p.asset.sector || "Other" }.transform_values do |group|
          group_value = group.sum { |p| p.shares * (p.asset.current_price || 0) }
          ((group_value / total) * 100).round(1)
        end
      end

      private_class_method :extract_performer, :extract_sector_weights
    end
  end
end
