module MarketData
  module Domain
    class PeHistoryCalculator
      def self.calculate(price_histories:, eps:)
        return [] if eps.nil? || eps.to_d.zero? || price_histories.empty?

        price_histories.map do |history|
          pe = (history.close.to_d / eps.to_d).round(2)
          { date: history.date, pe_ratio: pe }
        end
      end
    end
  end
end
