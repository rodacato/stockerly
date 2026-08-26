module MarketData
  module Domain
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

    # The gateways and the statement calculator name the same quantity
    # differently — Alpha Vantage and FMP persist `return_on_equity`, the
    # calculator writes `roe_calculated`, and the UI asks for `roe`. Without
    # this map six of the ten Resumen cards render "—" on data that did arrive.
    ALIASES = {
      "roe"              => %w[return_on_equity roe_calculated],
      "roa"              => %w[return_on_assets roa_calculated],
      "net_margin"       => %w[profit_margin],
      "ev_ebitda"        => %w[ev_to_ebitda],
      "ps_ratio"         => %w[price_to_sales],
      "pb_ratio"         => %w[price_to_book],
      "revenue_growth"   => %w[quarterly_revenue_growth],
      "eps_growth"       => %w[quarterly_earnings_growth],
      "total_volume_24h" => %w[total_volume]
    }.freeze

    # Accessor for any stored metric by key, canonical name first.
    def metric(key)
      name = key.to_s
      return @metrics[name] if @metrics[name].present?

      ALIASES.fetch(name, []).each do |alt|
        return @metrics[alt] if @metrics[alt].present?
      end
      nil
    end

    # Delegate unknown methods to stored metrics, aliases included.
    def method_missing(name, *args)
      value = metric(name)
      return value unless value.nil?
      super
    end

    def respond_to_missing?(name, include_private = false)
      key = name.to_s
      @metrics.key?(key) || ALIASES.fetch(key, []).any? { |alt| @metrics.key?(alt) } || super
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
  end
end
