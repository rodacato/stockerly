# Computes price-dependent metrics at render time using live current_price
# and stored fundamental data from AssetFundamental#metrics.
# This ensures P/E, P/B, P/S always reflect the latest market price.
class FundamentalPresenter
  attr_reader :asset, :fundamental

  def initialize(asset:, fundamental:)
    @asset = asset
    @fundamental = fundamental
    @metrics = fundamental&.metrics&.with_indifferent_access || {}
  end

  # Price-dependent metrics (computed live)
  def pe_ratio
    return nil unless @asset.current_price && eps&.nonzero?
    (@asset.current_price / eps).round(2)
  end

  def pb_ratio
    return nil unless @asset.current_price && book_value&.nonzero?
    (@asset.current_price / book_value).round(2)
  end

  def ps_ratio
    return nil unless @asset.current_price && revenue_per_share&.nonzero?
    (@asset.current_price / revenue_per_share).round(2)
  end

  def fcf_yield
    operating_cf = @metrics["operating_cashflow"]&.to_d
    capex = @metrics["capital_expenditures"]&.to_d
    market_cap = @metrics["market_cap"]&.to_d
    return nil unless operating_cf && capex && market_cap&.nonzero?

    fcf = operating_cf - capex.abs
    (fcf / market_cap).round(4)
  end

  # Accessor for any stored metric by key
  def metric(key)
    @metrics[key.to_s]
  end

  # Delegate unknown methods to stored metrics
  def method_missing(name, *args)
    key = name.to_s
    return @metrics[key] if @metrics.key?(key)
    super
  end

  def respond_to_missing?(name, include_private = false)
    @metrics.key?(name.to_s) || super
  end

  private

  def eps
    @metrics["eps"]&.to_d
  end

  def book_value
    @metrics["book_value"]&.to_d
  end

  def revenue_per_share
    @metrics["revenue_per_share"]&.to_d
  end
end
