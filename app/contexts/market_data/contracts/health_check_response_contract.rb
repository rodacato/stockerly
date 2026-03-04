module MarketData
  module Contracts
    class HealthCheckResponseContract < ApplicationContract
      params do
        required(:health_score).filled(:integer, gteq?: 0, lteq?: 100)
        required(:strengths).value(:array).each(:string)
        required(:concerns).value(:array).each(:string)
        required(:summary).filled(:string)
      end
    end
  end
end
