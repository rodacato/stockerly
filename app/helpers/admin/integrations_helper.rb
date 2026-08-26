module Admin
  module IntegrationsHelper
    PROVIDER_WEBSITES = {
      "Polygon.io"     => "polygon.io",
      "Finnhub"        => "finnhub.io",
      "CoinGecko"      => "coingecko.com",
      "Yahoo Finance"  => "finance.yahoo.com",
      "Alternative.me" => "alternative.me",
      "CNN"            => "cnn.com/markets/fear-and-greed",
      "Alpha Vantage"  => "alphavantage.co",
      "FMP"            => "financialmodelingprep.com",
      "ExchangeRate"   => "exchangerate-api.com",
      "Banxico"        => "banxico.org.mx"
    }.freeze

    CAPABILITY_LABELS = {
      prices:      "PRECIOS",
      historical:  "HISTÓRICO",
      indices:     "ÍNDICES",
      search:      "BÚSQUEDA",
      news:        "NOTICIAS",
      earnings:    "REPORTES",
      sentiment:   "SENTIMIENTO",
      market_data: "MARKETCAP",
      fundamentals: "FUNDAMENTALES",
      fx:          "TIPO DE CAMBIO",
      cetes:       "CETES"
    }.freeze

    # Pulls capability labels from the DataSourceRegistry entries that map
    # to this integration. Returns an es-MX uppercase string suitable as
    # the provider-card "capability" subtitle.
    def integration_capabilities_label(integration)
      caps = DataSourceRegistry.all
                               .select { |ds| ds.integration_name == integration.provider_name }
                               .flat_map(&:capabilities)
                               .uniq
      return "—" if caps.empty?
      caps.map { |c| CAPABILITY_LABELS[c] || c.to_s.upcase }.join(" · ")
    end

    def integration_website(integration)
      PROVIDER_WEBSITES[integration.provider_name]
    end

    # State for the Lumen status pill on a provider card.
    # connected → :active · syncing → :active · disconnected (no key) → :error
    def integration_pill_state(integration)
      if integration.requires_api_key? && !integration.api_key_configured?
        :paused
      else
        case integration.connection_status
        when "connected", "syncing" then :active
        when "disconnected"          then :error
        else :paused
        end
      end
    end

    def integration_pill_meta(state)
      case state
      when :active
        { label: "Activa",     fg: "text-positive", bg: "bg-positive/10", dot: "bg-positive" }
      when :paused
        { label: "Pausada",    fg: "text-warning",  bg: "bg-warning/10",  dot: "bg-warning" }
      when :error
        { label: "Error",      fg: "text-negative", bg: "bg-negative/10", dot: "bg-negative" }
      else
        { label: "Sin estado", fg: "text-fg-subtle", bg: "bg-bg-muted",   dot: "bg-fg-subtle" }
      end
    end

    def integration_rate_limit_label(integration)
      min  = integration.max_requests_per_minute
      day  = integration.daily_call_limit
      return "—" if min.blank? && day.blank?
      parts = []
      parts << "#{min} req/min" if min.present?
      parts << "#{number_with_delimiter(day)} req/día" if day.present?
      parts.join(" · ")
    end

    # `ajustes-integraciones` draws a usage bar the screen never showed, over
    # counters the table has carried all along. Minute window when the
    # provider is rate-limited per minute, daily otherwise.
    def integration_usage(integration)
      if integration.max_requests_per_minute.present?
        [ integration.minute_calls, integration.max_requests_per_minute, :minuto ]
      elsif integration.daily_call_limit.present?
        [ integration.daily_api_calls, integration.daily_call_limit, :dia ]
      end
    end

    def integration_usage_bar_classes(used, limit)
      return "bg-fg-subtle" if limit.to_i.zero?

      ratio = used.to_f / limit
      return "bg-negative" if ratio >= 1
      return "bg-warning"  if ratio >= 0.7

      "bg-positive"
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
