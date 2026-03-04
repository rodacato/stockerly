module MarketData
  module Contracts
    class InsightResponseContract < ApplicationContract
      params do
        required(:summary).filled(:string)
        required(:observations).value(:array).each(:string)
        optional(:risk_factors).value(:array).each(:string)
      end

      rule(:summary) do
        key.failure("must be at most 500 characters") if value.length > 500
      end

      rule(:observations) do
        key.failure("must have at most 5 items") if value.length > 5
      end
    end
  end
end
