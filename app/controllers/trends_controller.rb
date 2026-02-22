class TrendsController < ApplicationController
  layout "public"

  def index
    result = Trends::LoadAssetTrend.call(symbol: params[:symbol])

    if result.success?
      data     = result.value!
      @asset   = data[:asset]
      @score   = data[:score]
      @history = data[:history]
    else
      @asset   = nil
      @score   = nil
      @history = []
    end
  end
end
