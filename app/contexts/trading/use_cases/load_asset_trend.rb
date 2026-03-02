module Trading
  class LoadAssetTrend < ApplicationUseCase
    def call(symbol: nil)
      asset = symbol.present? ? Asset.find_by(symbol: symbol.upcase) : Asset.stocks.first
      return Failure([ :not_found, "Asset not found" ]) unless asset

      score = asset.latest_trend_score
      history = asset.asset_price_histories.recent.limit(30)

      Success({ asset: asset, score: score, history: history })
    end
  end
end
