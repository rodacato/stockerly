module Admin
  module IntegrationsHelper
    PROVIDER_WEBSITES = {
      "Finnhub"        => "finnhub.io",
      "CoinGecko"      => "coingecko.com",
      "Yahoo Finance"  => "finance.yahoo.com",
      "Alternative.me" => "alternative.me",
      "Alpha Vantage"  => "alphavantage.co",
      "FMP"            => "financialmodelingprep.com",
      "ExchangeRate"   => "exchangerate-api.com",
      "Banxico"        => "banxico.org.mx",
      "Alpaca"         => "alpaca.markets",
      "DataBursatil"   => "databursatil.com"
    }.freeze

    # Alpaca is the only provider whose credential is two values. The gateway
    # splits the stored key on the colon, so the field has to ask for both.
    PROVIDER_KEY_FORMATS = {
      "Alpaca" => "KEY_ID:SECRET"
    }.freeze

    CAPABILITY_LABELS = {
      prices:      "PRECIOS",
      historical:  "HISTÓRICO",
      indices:     "ÍNDICES",
      search:      "BÚSQUEDA",
      news:        "NOTICIAS",
      earnings:    "REPORTES",
      dividends:   "DIVIDENDOS",
      splits:      "SPLITS",
      sentiment:   "SENTIMIENTO",
      market_data: "MARKETCAP",
      fundamentals: "FUNDAMENTALES",
      fx:          "TIPO DE CAMBIO",
      cetes:       "CETES"
    }.freeze

    def capabilities_label(capabilities)
      return "—" if capabilities.empty?

      capabilities.map { |c| CAPABILITY_LABELS[c] || c.to_s.upcase }.join(" · ")
    end

    def integration_website(integration)
      PROVIDER_WEBSITES[integration.provider_name]
    end

    def integration_key_placeholder(integration)
      integration.masked_api_key ||
        PROVIDER_KEY_FORMATS[integration.provider_name] ||
        t("admin.integrations.index.clave")
    end

    # D40's four states, and the token each paints with. `sin cuota` is our own
    # counter and `bloqueada` is the provider refusing — different colours
    # because they are different problems.
    STATE_STYLES = {
      connected: { dot: "bg-positive", fg: "text-positive", bar: "bg-positive" },
      no_key:    { dot: "bg-fg-subtle", fg: "text-fg-subtle", bar: "bg-fg-subtle" },
      no_quota:  { dot: "bg-warning",  fg: "text-warning",  bar: "bg-warning" },
      blocked:   { dot: "bg-negative", fg: "text-negative", bar: "bg-negative" }
    }.freeze

    STATE_REASONS = {
      no_key:   { key: "sin_llave_razon", icon: "key",   bg: "bg-bg-muted",     fg: "text-fg-subtle" },
      no_quota: { key: "sin_cuota_razon", icon: "hourglass_top", bg: "bg-warning-bg", fg: "text-warning-fg" },
      blocked:  { key: "bloqueada_razon", icon: "gpp_maybe", bg: "bg-negative-bg", fg: "text-negative-fg" }
    }.freeze

    def source_state_style(state)
      STATE_STYLES.fetch(state, STATE_STYLES[:no_key])
    end

    def source_state_reason(state)
      STATE_REASONS[state]
    end

    def source_state_label(state)
      t("admin.integrations.index.estado.#{state}")
    end

    def source_role_label(role)
      t("admin.integrations.index.rol.#{role}")
    end

    # A near-limit source is still connected; the bar is what warns, so it
    # carries the warning colour rather than the state's.
    def source_bar_classes(entry)
      return "bg-warning" if entry.state == :connected && entry.quota.near_limit?

      source_state_style(entry.state)[:bar]
    end

    def source_quota_label(quota)
      return t("admin.integrations.index.cuota_desconocida") unless quota.known?

      t("admin.integrations.index.uso",
        used: number_with_delimiter(quota.used),
        limit: number_with_delimiter(quota.limit),
        unit: t("admin.integrations.index.unidad.#{quota.unit}"))
    end

    def integration_last_check_label(integration)
      ts = integration.last_sync_at
      return "nunca" unless ts
      # Clamp at 0 to avoid "hace -1 s" when client/server clock skew
      # makes the timestamp slightly in the future.
      seconds = [ (Time.current - ts).to_i, 0 ].max
      return "hace #{seconds} s" if seconds < 60
      return "hace #{seconds / 60} min" if seconds < 3600
      return "hace #{seconds / 3600} h" if seconds < 86_400
      "hace #{seconds / 86_400} d"
    end

    # Returns the last 4 chars of the api key (visible).
  end
end
