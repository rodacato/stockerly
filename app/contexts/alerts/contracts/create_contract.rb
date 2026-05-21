module Alerts
  module Contracts
    class CreateContract < ApplicationContract
      ALLOWED_CONDITIONS = %w[
        price_crosses_above
        price_crosses_below
        day_change_percent
        rsi_overbought
        rsi_oversold
        volume_spike
        dividend_ex_date
      ].freeze

      params do
        required(:asset_symbol).filled(:string)
        required(:condition).filled(:string, included_in?: ALLOWED_CONDITIONS)
        required(:threshold_value).filled(:float)
        optional(:window_days).maybe(:integer)
      end

      rule(:window_days, :condition) do
        if values[:condition] == "dividend_ex_date" && values[:window_days].to_i < 1
          key(:window_days).failure("debe ser al menos 1 día para alertas de dividendo")
        end
      end
    end
  end
end
