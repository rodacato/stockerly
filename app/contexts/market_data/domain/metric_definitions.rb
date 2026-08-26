module MarketData
  module Domain
    # In-memory registry for financial metric definitions.
    # Follows the same pattern as DataSourceRegistry — boot-time registration,
    # class-level accessor, and clear! for tests.
    class MetricDefinitions
    # No copy here on purpose: name, description and guidance are user-facing
    # text and live in `market.metricas.<key>.*` (ADR-0011). The domain holds
    # the key; `MarketHelper#metric_*` resolves it. Adding a label back here
    # would put es-MX in a layer I18n cannot reach.
    Definition = Data.define(
      :key,           # Symbol, e.g. :pe_ratio
      :category,      # Symbol: :valuation, :profitability, :health, :growth, :dividends, :risk, :identity
      :format_type,   # :ratio, :percentage, :currency, :number, :text
      :display_order, # Integer for sorting within category
      :icon           # Material Symbol name
    )

    @definitions = {}

    class << self
      def register(key, **attrs)
        @definitions[key] = Definition.new(key: key, **attrs)
      end

      def find(key)
        @definitions.fetch(key) { raise KeyError, "Unknown metric: #{key}" }
      end

      def by_category(category)
        @definitions.values.select { |d| d.category == category }.sort_by(&:display_order)
      end

      def categories
        @definitions.values.map(&:category).uniq
      end

      def all
        @definitions.values
      end

      def clear!
        @definitions = {}
      end
    end

    # ── Valuation ──────────────────────────────────────────────
    register :pe_ratio,
      category: :valuation, format_type: :ratio, display_order: 1, icon: "price_change"

    register :forward_pe,
      category: :valuation, format_type: :ratio, display_order: 2, icon: "trending_up"

    register :pb_ratio,
      category: :valuation, format_type: :ratio, display_order: 3, icon: "menu_book"

    register :ps_ratio,
      category: :valuation, format_type: :ratio, display_order: 4, icon: "receipt_long"

    register :ev_ebitda,
      category: :valuation, format_type: :ratio, display_order: 5, icon: "corporate_fare"

    register :peg_ratio,
      category: :valuation, format_type: :ratio, display_order: 6, icon: "speed"

    register :market_cap,
      category: :valuation, format_type: :currency, display_order: 7, icon: "account_balance"

    register :fcf_yield,
      category: :valuation, format_type: :percentage, display_order: 8, icon: "water_drop"

    # ── Profitability ──────────────────────────────────────────
    register :roe,
      category: :profitability, format_type: :percentage, display_order: 1, icon: "trending_up"

    register :roa,
      category: :profitability, format_type: :percentage, display_order: 2, icon: "inventory_2"

    register :net_margin,
      category: :profitability, format_type: :percentage, display_order: 3, icon: "savings"

    register :operating_margin,
      category: :profitability, format_type: :percentage, display_order: 4, icon: "precision_manufacturing"

    register :gross_margin,
      category: :profitability, format_type: :percentage, display_order: 5, icon: "storefront"

    register :ebitda,
      category: :profitability, format_type: :currency, display_order: 6, icon: "payments"

    # ── Financial Health ───────────────────────────────────────
    register :debt_to_equity,
      category: :health, format_type: :ratio, display_order: 1, icon: "balance"

    register :current_ratio,
      category: :health, format_type: :ratio, display_order: 2, icon: "water"

    register :quick_ratio,
      category: :health, format_type: :ratio, display_order: 3, icon: "bolt"

    # ── Growth ─────────────────────────────────────────────────
    register :revenue_growth,
      category: :growth, format_type: :percentage, display_order: 1, icon: "show_chart"

    register :eps_growth,
      category: :growth, format_type: :percentage, display_order: 2, icon: "trending_up"

    register :revenue_ttm,
      category: :growth, format_type: :currency, display_order: 3, icon: "point_of_sale"

    register :eps,
      category: :growth, format_type: :currency, display_order: 4, icon: "monetization_on"

    # ── Dividends ──────────────────────────────────────────────
    register :dividend_yield,
      category: :dividends, format_type: :percentage, display_order: 1, icon: "redeem"

    register :payout_ratio,
      category: :dividends, format_type: :percentage, display_order: 2, icon: "pie_chart"

    register :dividend_per_share,
      category: :dividends, format_type: :currency, display_order: 3, icon: "paid"

    # ── Risk ───────────────────────────────────────────────────
    register :beta,
      category: :risk, format_type: :ratio, display_order: 1, icon: "ssid_chart"

    register :fifty_two_week_high,
      category: :risk, format_type: :currency, display_order: 2, icon: "arrow_upward"

    register :fifty_two_week_low,
      category: :risk, format_type: :currency, display_order: 3, icon: "arrow_downward"

    # ── Identity ───────────────────────────────────────────────
    register :sector,
      category: :identity, format_type: :text, display_order: 1, icon: "category"

    register :exchange,
      category: :identity, format_type: :text, display_order: 2, icon: "language"

    register :shares_outstanding,
      category: :identity, format_type: :number, display_order: 3, icon: "confirmation_number"

    # ── Crypto Market ────────────────────────────────────────
    register :circulating_supply,
      category: :crypto_market, format_type: :number, display_order: 1, icon: "toll"

    register :total_supply,
      category: :crypto_market, format_type: :number, display_order: 2, icon: "database"

    register :fully_diluted_valuation,
      category: :crypto_market, format_type: :currency, display_order: 3, icon: "account_balance_wallet"

    register :total_volume_24h,
      category: :crypto_market, format_type: :currency, display_order: 4, icon: "bar_chart"

    register :ath_price,
      category: :crypto_market, format_type: :currency, display_order: 5, icon: "emoji_events"

    register :volume_market_cap_ratio,
      category: :crypto_market, format_type: :percentage, display_order: 6, icon: "swap_horiz"
    end
  end
end
