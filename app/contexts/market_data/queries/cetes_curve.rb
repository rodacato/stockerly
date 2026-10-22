module MarketData
  module Queries
    # ADR-031: the latest auction yield of each CETES term, each with its own
    # auction date, since the terms are not always auctioned the same week.
    class CetesCurve
      # @api public
      def self.call
        CetesRateHistory::TERMS.filter_map do |term|
          row = CetesRateHistory.for_term(term).order(auction_date: :desc).first
          row && { term: term.to_i, yield_rate: row.yield_rate, auction_date: row.auction_date, source: row.source }.freeze
        end.freeze
      end
    end
  end
end
