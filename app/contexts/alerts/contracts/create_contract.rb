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
        bmv_holiday
        cete_auction
      ].freeze

      # Conditions that fire on a marketwide calendar date — no asset binding.
      MARKETWIDE_CONDITIONS = %w[bmv_holiday cete_auction].freeze

      # Conditions evaluated by the date-based job (require window_days, not
      # threshold_value).
      DATE_BASED_CONDITIONS = %w[dividend_ex_date bmv_holiday cete_auction].freeze

      params do
        optional(:asset_symbol).maybe(:string)
        required(:condition).filled(:string, included_in?: ALLOWED_CONDITIONS)
        optional(:threshold_value).maybe(:float)
        optional(:window_days).maybe(:integer)
      end

      rule(:asset_symbol, :condition) do
        next if MARKETWIDE_CONDITIONS.include?(values[:condition])
        key(:asset_symbol).failure("requerido") if values[:asset_symbol].blank?
      end

      rule(:threshold_value, :condition) do
        next if DATE_BASED_CONDITIONS.include?(values[:condition])
        key(:threshold_value).failure("requerido") if values[:threshold_value].nil?
      end

      rule(:window_days, :condition) do
        if DATE_BASED_CONDITIONS.include?(values[:condition]) && values[:window_days].to_i < 1
          key(:window_days).failure("debe ser al menos 1 día para alertas por fecha")
        end
      end
    end
  end
end
