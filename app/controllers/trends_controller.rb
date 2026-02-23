class TrendsController < ApplicationController
  layout "public"

  def index
    result = Trends::LoadAssetTrend.call(symbol: params[:symbol])

    if result.success?
      data     = result.value!
      @asset   = data[:asset]
      @score   = data[:score]
      @history = data[:history]
      @market_open = @asset ? MarketHours.open_for_asset?(@asset) : false
    else
      @asset   = nil
      @score   = nil
      @history = []
      @market_open = false
    end
  end
end
