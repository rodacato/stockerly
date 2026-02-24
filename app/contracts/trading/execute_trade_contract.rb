module Trading
  class ExecuteTradeContract < ApplicationContract
    params do
      required(:asset_symbol).filled(:string)
      required(:side).filled(:string, included_in?: %w[buy sell])
      required(:shares).filled(:float)
      required(:price_per_share).filled(:float)
      optional(:fee).maybe(:float)
      optional(:executed_at).maybe(:string)
    end

    rule(:shares) do
      key.failure("must be greater than 0") if value <= 0
    end

    rule(:price_per_share) do
      key.failure("must be greater than 0") if value <= 0
    end

    rule(:asset_symbol) do
      key.failure("asset not found") unless Asset.exists?(symbol: value.upcase)
    end
  end
end
