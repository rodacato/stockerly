module FundamentalsHelper
  # D36: an interpretive chip is only built where the threshold is part of the
  # metric's own definition, never where it varies by industry. Beta is scaled
  # against the market by construction; a payout above 100% pays more than it
  # earns; a current ratio below 1.0 does not cover the near term. P/E "caro vs
  # su historia" is deliberately absent — it needs the asset's own P/E history,
  # which this partial is not given.
  METRIC_CHIPS = {
    beta: ->(v) {
      return :volatil    if v > 1.3
      return :defensivo  if v < 0.7
      :como_el_mercado
    },
    payout_ratio: ->(v) { :sobre_utilidades if v > 1.0 },
    current_ratio: ->(v) { v < 1.0 ? :liquidez_corta : :cubre_corto_plazo }
  }.freeze

  CHIP_TONES = {
    volatil:           "bg-warning-bg text-warning",
    defensivo:         "bg-bg-muted text-fg-subtle",
    como_el_mercado:   "bg-bg-muted text-fg-subtle",
    sobre_utilidades:  "bg-negative-bg text-negative-fg",
    liquidez_corta:    "bg-warning-bg text-warning",
    cubre_corto_plazo: "bg-positive-bg text-positive-fg"
  }.freeze

  def metric_name(definition)     = t("market.metricas.#{definition.key}.nombre")
  def metric_desc(definition)     = t("market.metricas.#{definition.key}.desc")
  def metric_guidance(definition) = t("market.metricas.#{definition.key}.guia")

  # Returns [label, classes] or nil when the metric has no defensible threshold.
  def metric_chip(definition, value)
    return if value.nil?
    rule = METRIC_CHIPS[definition.key]
    return unless rule

    key = rule.call(value.to_f)
    return unless key

    [ t("market.chips.#{key}"), CHIP_TONES.fetch(key) ]
  end

  def format_metric_value(value, format_type, currency:)
    return "—" if value.nil?

    case format_type
    when :ratio      then number_with_precision(value.to_f, precision: 2)
    # Every producer stores a percentage as a decimal ratio — Alpha Vantage and
    # FMP persist ProfitMargin as 0.2461, and FundamentalCalculator rounds
    # net/revenue to 4 places. Printing it raw showed a 24.6% margin as "0.2%".
    when :percentage then "#{number_with_precision(value.to_f * 100, precision: 1)}%"
    when :currency   then format_large_currency(value, currency: currency)
    when :number     then number_with_delimiter(value.to_i)
    when :text       then value.to_s
    else value.to_s
    end
  end

  # The currency is required, not decorative: market cap is read on a screen
  # that mixes BMV and NASDAQ issuers, where a bare "$" names neither.
  def format_large_currency(value, currency:)
    v = value.to_f
    if v.abs >= 1_000_000_000_000
      "#{format_currency_mx(v / 1e12, currency: currency, precision: 2)}T"
    elsif v.abs >= 1_000_000_000
      "#{format_currency_mx(v / 1e9, currency: currency, precision: 1)}B"
    elsif v.abs >= 1_000_000
      "#{format_currency_mx(v / 1e6, currency: currency, precision: 1)}M"
    else
      format_currency_mx(v, currency: currency)
    end
  end

  def gaap_label(asset)
    asset.country == "US" ? "US GAAP" : "As reported"
  end

  # Five, and each one answers a question a reader can say out loud (#429, D70).
  # The five that went: ev_ebitda and fcf_yield ask you to already know what
  # EBITDA and free cash flow are, eps says nothing without the price beside it,
  # beta is a trader's number, market_cap is context rather than a judgement,
  # and roe restates net_margin for a holder who is not comparing capital
  # structures. dividend_yield was not among the ten and is the only one here
  # that answers in money.
  SUMMARY_METRICS = %i[
    pe_ratio net_margin revenue_growth debt_to_equity dividend_yield
  ].freeze

  CRYPTO_SUMMARY_METRICS = %i[
    market_cap circulating_supply fully_diluted_valuation
    total_volume_24h ath_price volume_market_cap_ratio
  ].freeze

  def summary_metrics_for(asset)
    asset.asset_type_crypto? ? CRYPTO_SUMMARY_METRICS : SUMMARY_METRICS
  end

  # What the "Ver todos" accordion shows: every metric the extract left out,
  # grouped by category. Crypto categories are dropped for an equity and the
  # reverse, and a metric with no value is dropped entirely — twenty cards
  # reading "—" is not depth, it is noise.
  def remaining_metrics_by_category(asset, presenter)
    shown = summary_metrics_for(asset)
    excluded = asset.asset_type_crypto? ? %i[identity dividends] : %i[identity crypto_market]

    MarketData::Domain::MetricDefinitions.all
      .reject { |d| shown.include?(d.key) || excluded.include?(d.category) }
      .select { |d| resolve_metric_value(presenter, d.key).present? }
      .group_by(&:category)
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
