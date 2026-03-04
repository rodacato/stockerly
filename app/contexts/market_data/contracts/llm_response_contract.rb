module MarketData
  module Contracts
    class LlmResponseContract < ApplicationContract
      params do
        required(:content).filled(:string)
        required(:provider).filled(:string)
      end

      rule(:content) do
        key.failure("must be at most 5000 characters") if value.length > 5000
      end
    end
  end
end
