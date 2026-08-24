module Trading
  module Contracts
    class ExecuteTradeContract < ApplicationContract
      POSITIVE_VALUE_ERROR = "must be greater than 0"

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
        key.failure(POSITIVE_VALUE_ERROR) if value <= 0
      end

      rule(:price_per_share) do
        key.failure(POSITIVE_VALUE_ERROR) if value <= 0
      end

      rule(:fx_rate_at_execution) do
        key.failure(POSITIVE_VALUE_ERROR) if value && value <= 0
      end

      rule(:asset_symbol) do
        key.failure("asset not found") unless Asset.exists?(symbol: value.upcase)
      end

      # JTBD #5 already specifies `max: today`, and nothing enforced it: a trade
      # dated 90 days out was accepted, opening a position that does not exist
      # yet and counting it into today's figures. The message reaches the user
      # verbatim through the sheet's flash, so it is es-MX.
      rule(:executed_at) do
        next if value.blank?

        parsed = begin
          Date.parse(value)
        rescue ArgumentError, TypeError
          nil
        end

        if parsed.nil?
          key.failure(I18n.t("trades.errores.fecha_invalida"))
        elsif parsed > Date.current
          key.failure(I18n.t("trades.errores.fecha_futura"))
        end
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
