module Alerts
  class CreateContract < ApplicationContract
    params do
      required(:asset_symbol).filled(:string)
      required(:condition).filled(:string, included_in?: %w[price_crosses_above price_crosses_below day_change_percent rsi_overbought rsi_oversold])
      required(:threshold_value).filled(:float)
    end
  end
end
