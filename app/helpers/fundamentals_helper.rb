module FundamentalsHelper
  def format_metric_value(value, format_type)
    return "—" if value.nil?

    case format_type
    when :ratio      then number_with_precision(value.to_f, precision: 2)
    when :percentage then "#{number_with_precision(value.to_f, precision: 1)}%"
    when :currency   then format_large_currency(value)
    when :number     then number_with_delimiter(value.to_i)
    when :text       then value.to_s
    else value.to_s
    end
  end

  def format_large_currency(value)
    v = value.to_f
    if v.abs >= 1_000_000_000_000
      "$#{number_with_precision(v / 1e12, precision: 2)}T"
    elsif v.abs >= 1_000_000_000
      "$#{number_with_precision(v / 1e9, precision: 1)}B"
    elsif v.abs >= 1_000_000
      "$#{number_with_precision(v / 1e6, precision: 1)}M"
    else
      number_to_currency(v)
    end
  end

  def gaap_label(asset)
    asset.country == "US" ? "US GAAP" : "As reported"
  end

  SUMMARY_METRICS = %i[
    pe_ratio ev_ebitda market_cap roe net_margin
    fcf_yield revenue_growth eps debt_to_equity beta
  ].freeze

  CRYPTO_SUMMARY_METRICS = %i[
    market_cap circulating_supply fully_diluted_valuation
    total_volume_24h ath_price volume_market_cap_ratio
  ].freeze

  def summary_metrics_for(asset)
    asset.asset_type_crypto? ? CRYPTO_SUMMARY_METRICS : SUMMARY_METRICS
  end

  def resolve_metric_value(presenter, key)
    # Try computed methods first (pe_ratio, pb_ratio, etc.)
    if presenter.respond_to?(key)
      presenter.public_send(key)
    else
      presenter.metric(key.to_s)
    end
  end
end
