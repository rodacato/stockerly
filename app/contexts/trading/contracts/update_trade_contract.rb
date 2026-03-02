module Trading
  module Contracts
    class UpdateTradeContract < ApplicationContract
      params do
        required(:trade_id).filled(:integer)
        optional(:shares).filled(:float)
        optional(:price_per_share).filled(:float)
        optional(:fee).maybe(:float)
        optional(:executed_at).maybe(:string)
      end

      rule(:shares) do
        key.failure("must be greater than 0") if key? && value <= 0
      end

      rule(:price_per_share) do
        key.failure("must be greater than 0") if key? && value <= 0
      end

      rule(:trade_id) do
        key.failure("trade not found") unless Trade.exists?(id: value)
      end
    end
  end
end
