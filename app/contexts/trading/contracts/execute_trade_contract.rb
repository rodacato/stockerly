module Trading
  module Contracts
    class ExecuteTradeContract < ApplicationContract
      params do
        required(:asset_symbol).filled(:string)
        required(:side).filled(:string, included_in?: %w[buy sell])
        required(:shares).filled(:float)
        required(:price_per_share).filled(:float)
        optional(:fee).maybe(:float)
        optional(:executed_at).maybe(:string)
        optional(:currency).maybe(:string, included_in?: Asset::SUPPORTED_CURRENCIES)
        optional(:fx_rate_at_execution).maybe(:decimal)
        optional(:maturity_date).maybe(:string)
      end

      rule(:shares) do
        key.failure("must be greater than 0") if value <= 0
      end

      rule(:price_per_share) do
        key.failure("must be greater than 0") if value <= 0
      end

      rule(:fx_rate_at_execution) do
        key.failure("must be greater than 0") if value && value <= 0
      end

      rule(:asset_symbol) do
        key.failure("asset not found") unless Asset.exists?(symbol: value.upcase)
      end

      # Fixed-income lots (CETES, future Bonos M, UDIs) carry a per-position
      # maturity captured at purchase — Asset.maturity_date is meaningless
      # because the instrument rolls (#29 JTBD #3). The contract requires it
      # only for the fixed_income asset_type; other types stay backward-
      # compatible (Asset existence is validated above; nil asset short-circuits).
      rule(:maturity_date, :asset_symbol) do
        asset = Asset.find_by(symbol: values[:asset_symbol]&.upcase)
        next unless asset&.asset_type_fixed_income?

        if values[:maturity_date].blank?
          key.failure("required for fixed-income assets")
        else
          parsed = begin
            Date.parse(values[:maturity_date])
          rescue ArgumentError, TypeError
            nil
          end

          if parsed.nil?
            key.failure("must be a valid date")
          elsif parsed <= Date.current
            key.failure("must be in the future")
          end
        end
      end
    end
  end
end
