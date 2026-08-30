module Trading
  module Contracts
    # Shape only. Unlike ExecuteTradeContract this does NOT check that the asset
    # exists: an unknown symbol is a resolvable finding the importer reports as
    # its own category, not a malformed row.
    class ImportTradeRowContract < ApplicationContract
      POSITIVE_VALUE_ERROR = "must be greater than 0"

      params do
        required(:asset_symbol).filled(:string)
        required(:side).filled(:string, included_in?: %w[buy sell])
        required(:shares).filled(:decimal)
        required(:price_per_share).filled(:decimal)
        required(:executed_at).filled(:string)
        optional(:fee).maybe(:decimal)
        required(:currency).filled(:string, included_in?: Asset::SUPPORTED_CURRENCIES)
        optional(:external_id).maybe(:string)
        optional(:net_amount).maybe(:decimal)
      end

      rule(:shares) { key.failure(POSITIVE_VALUE_ERROR) if value <= 0 }
      rule(:price_per_share) { key.failure(POSITIVE_VALUE_ERROR) if value <= 0 }

      rule(:executed_at) do
        parsed = begin
          Time.zone.parse(value)
        rescue ArgumentError, TypeError
          nil
        end

        if parsed.nil?
          key.failure("is not a valid date")
        elsif parsed.to_date > Date.current
          key.failure("is in the future")
        end
      end

      # The broker states what it charged; the row states shares and price.
      # When both are present they must agree, because a silent disagreement is
      # how a six-decimal column quietly loses money on fractional shares.
      rule(:net_amount, :shares, :price_per_share) do
        next if values[:net_amount].nil?

        computed = values[:shares] * values[:price_per_share]
        drift = (computed - values[:net_amount].abs).abs
        key(:net_amount).failure("does not match shares x price (off by #{drift.round(4)})") if drift > 0.01
      end
    end
  end
end
