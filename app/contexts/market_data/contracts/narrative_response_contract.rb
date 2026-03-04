module MarketData
  module Contracts
    class NarrativeResponseContract < ApplicationContract
      params do
        required(:narrative).filled(:string)
        required(:pattern).filled(:string, included_in?: %w[consistent improving declining mixed])
        required(:consistency_score).filled(:integer, gteq?: 0, lteq?: 100)
      end
    end
  end
end
