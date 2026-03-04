module MarketData
  module Contracts
    class SentimentResponseContract < ApplicationContract
      params do
        required(:articles).value(:array).each do
          hash do
            required(:title).filled(:string)
            required(:sentiment).filled(:string, included_in?: %w[bullish bearish neutral])
            required(:score).filled(:integer, gteq?: 0, lteq?: 100)
          end
        end
      end
    end
  end
end
