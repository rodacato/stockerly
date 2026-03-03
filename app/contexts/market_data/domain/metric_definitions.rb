module MarketData
  module Domain
    # In-memory registry for financial metric definitions.
    # Follows the same pattern as DataSourceRegistry — boot-time registration,
    # class-level accessor, and clear! for tests.
    class MetricDefinitions
    Definition = Data.define(
      :key,              # Symbol, e.g. :pe_ratio
      :category,         # Symbol: :valuation, :profitability, :health, :growth, :dividends, :risk, :identity
      :display_name,     # "P/E Ratio"
      :short_desc,       # "Price relative to earnings"
      :context_guidance, # "A high P/E may indicate growth expectations or overvaluation."
      :format_type,      # :ratio, :percentage, :currency, :number, :text
      :display_order,    # Integer for sorting within category
      :icon              # Material Symbol name
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
      category: :valuation, display_name: "P/E Ratio",
      short_desc: "Price relative to earnings per share",
      context_guidance: "Compares current price to earnings. A higher P/E may reflect growth expectations; a lower P/E may suggest undervaluation or declining earnings.",
      format_type: :ratio, display_order: 1, icon: "price_change"

    register :forward_pe,
      category: :valuation, display_name: "Forward P/E",
      short_desc: "Price relative to estimated future earnings",
      context_guidance: "Uses analyst consensus for next 12-month EPS. Compare against trailing P/E to gauge market growth expectations.",
      format_type: :ratio, display_order: 2, icon: "trending_up"

    register :pb_ratio,
      category: :valuation, display_name: "P/B Ratio",
      short_desc: "Price relative to book value per share",
      context_guidance: "Compares market price to net asset value. Asset-heavy industries typically have lower P/B ratios.",
      format_type: :ratio, display_order: 3, icon: "menu_book"

    register :ps_ratio,
      category: :valuation, display_name: "P/S Ratio",
      short_desc: "Price relative to revenue per share",
      context_guidance: "Useful for companies without earnings. Lower values may indicate undervaluation relative to revenue generation.",
      format_type: :ratio, display_order: 4, icon: "receipt_long"

    register :ev_ebitda,
      category: :valuation, display_name: "EV/EBITDA",
      short_desc: "Enterprise value relative to operating earnings",
      context_guidance: "Capital-structure neutral valuation metric. Generally more comparable across companies than P/E.",
      format_type: :ratio, display_order: 5, icon: "corporate_fare"

    register :peg_ratio,
      category: :valuation, display_name: "PEG Ratio",
      short_desc: "P/E adjusted for earnings growth rate",
      context_guidance: "A PEG near 1.0 suggests fair value relative to growth. Below 1.0 may indicate undervaluation.",
      format_type: :ratio, display_order: 6, icon: "speed"

    register :market_cap,
      category: :valuation, display_name: "Market Cap",
      short_desc: "Total market value of outstanding shares",
      context_guidance: "Market capitalization indicates company size. Large-cap (>$10B) tends to be more stable than small-cap (<$2B).",
      format_type: :currency, display_order: 7, icon: "account_balance"

    register :fcf_yield,
      category: :valuation, display_name: "FCF Yield",
      short_desc: "Free cash flow relative to market cap",
      context_guidance: "Indicates how much cash the business generates relative to its price. Higher yield may suggest better value.",
      format_type: :percentage, display_order: 8, icon: "water_drop"

    # ── Profitability ──────────────────────────────────────────
    register :roe,
      category: :profitability, display_name: "Return on Equity",
      short_desc: "Net income relative to shareholder equity",
      context_guidance: "Measures efficiency of equity capital. Consistently high ROE may indicate competitive advantage, but very high values can signal excessive leverage.",
      format_type: :percentage, display_order: 1, icon: "trending_up"

    register :roa,
      category: :profitability, display_name: "Return on Assets",
      short_desc: "Net income relative to total assets",
      context_guidance: "Measures how efficiently assets generate profit. Asset-heavy industries typically have lower ROA.",
      format_type: :percentage, display_order: 2, icon: "inventory_2"

    register :net_margin,
      category: :profitability, display_name: "Net Margin",
      short_desc: "Net income as a percentage of revenue",
      context_guidance: "Indicates the portion of revenue retained as profit after all expenses. Compare within the same industry for meaningful analysis.",
      format_type: :percentage, display_order: 3, icon: "savings"

    register :operating_margin,
      category: :profitability, display_name: "Operating Margin",
      short_desc: "Operating income as a percentage of revenue",
      context_guidance: "Reflects core business profitability before interest and taxes. Less affected by financing decisions than net margin.",
      format_type: :percentage, display_order: 4, icon: "precision_manufacturing"

    register :gross_margin,
      category: :profitability, display_name: "Gross Margin",
      short_desc: "Gross profit as a percentage of revenue",
      context_guidance: "Indicates pricing power and production efficiency. Higher margins typically signal competitive advantages.",
      format_type: :percentage, display_order: 5, icon: "storefront"

    register :ebitda,
      category: :profitability, display_name: "EBITDA",
      short_desc: "Earnings before interest, taxes, depreciation & amortization",
      context_guidance: "Proxy for operating cash generation. Useful for comparing companies with different capital structures.",
      format_type: :currency, display_order: 6, icon: "payments"

    # ── Financial Health ───────────────────────────────────────
    register :debt_to_equity,
      category: :health, display_name: "Debt-to-Equity",
      short_desc: "Total debt relative to shareholder equity",
      context_guidance: "Measures financial leverage. Higher ratios indicate more debt-funded operations, increasing financial risk.",
      format_type: :ratio, display_order: 1, icon: "balance"

    register :current_ratio,
      category: :health, display_name: "Current Ratio",
      short_desc: "Current assets relative to current liabilities",
      context_guidance: "Measures short-term liquidity. A ratio above 1.0 indicates ability to cover near-term obligations.",
      format_type: :ratio, display_order: 2, icon: "water"

    register :quick_ratio,
      category: :health, display_name: "Quick Ratio",
      short_desc: "Liquid assets relative to current liabilities",
      context_guidance: "Stricter liquidity measure excluding inventory. Often more relevant for service companies.",
      format_type: :ratio, display_order: 3, icon: "bolt"

    # ── Growth ─────────────────────────────────────────────────
    register :revenue_growth,
      category: :growth, display_name: "Revenue Growth",
      short_desc: "Quarter-over-quarter revenue change",
      context_guidance: "Indicates business momentum. Sustained growth may signal expanding market share or new product success.",
      format_type: :percentage, display_order: 1, icon: "show_chart"

    register :eps_growth,
      category: :growth, display_name: "EPS Growth",
      short_desc: "Quarter-over-quarter earnings per share change",
      context_guidance: "Measures earnings momentum. Accelerating EPS growth often drives share price appreciation.",
      format_type: :percentage, display_order: 2, icon: "trending_up"

    register :revenue_ttm,
      category: :growth, display_name: "Revenue (TTM)",
      short_desc: "Total revenue over the trailing twelve months",
      context_guidance: "Trailing twelve-month revenue provides a smoothed view of the business scale, removing seasonal distortions.",
      format_type: :currency, display_order: 3, icon: "point_of_sale"

    register :eps,
      category: :growth, display_name: "EPS (Diluted)",
      short_desc: "Earnings per share on a diluted basis",
      context_guidance: "Net income divided by diluted shares outstanding. The primary per-share profitability measure used in P/E calculations.",
      format_type: :currency, display_order: 4, icon: "monetization_on"

    # ── Dividends ──────────────────────────────────────────────
    register :dividend_yield,
      category: :dividends, display_name: "Dividend Yield",
      short_desc: "Annual dividend relative to share price",
      context_guidance: "Indicates income return on investment. Very high yields may signal unsustainable payouts or declining share price.",
      format_type: :percentage, display_order: 1, icon: "redeem"

    register :payout_ratio,
      category: :dividends, display_name: "Payout Ratio",
      short_desc: "Dividends as percentage of earnings",
      context_guidance: "Shows what portion of earnings is distributed. A ratio above 100% means dividends exceed earnings.",
      format_type: :percentage, display_order: 2, icon: "pie_chart"

    register :dividend_per_share,
      category: :dividends, display_name: "Dividend/Share",
      short_desc: "Annual dividend payment per share",
      context_guidance: "The absolute dollar amount paid annually per share. Track consistency and growth over time.",
      format_type: :currency, display_order: 3, icon: "paid"

    # ── Risk ───────────────────────────────────────────────────
    register :beta,
      category: :risk, display_name: "Beta",
      short_desc: "Volatility relative to the market",
      context_guidance: "Beta of 1.0 means market-level volatility. Above 1.0 indicates higher volatility; below 1.0 indicates lower.",
      format_type: :ratio, display_order: 1, icon: "ssid_chart"

    register :fifty_two_week_high,
      category: :risk, display_name: "52-Week High",
      short_desc: "Highest price in the past year",
      context_guidance: "Reference point for recent price ceiling. Proximity to 52-week high may indicate momentum or resistance.",
      format_type: :currency, display_order: 2, icon: "arrow_upward"

    register :fifty_two_week_low,
      category: :risk, display_name: "52-Week Low",
      short_desc: "Lowest price in the past year",
      context_guidance: "Reference point for recent price floor. Proximity to 52-week low may indicate weakness or support.",
      format_type: :currency, display_order: 3, icon: "arrow_downward"

    # ── Identity ───────────────────────────────────────────────
    register :sector,
      category: :identity, display_name: "Sector",
      short_desc: "Industry classification",
      context_guidance: "The economic sector this company operates in. Sector context is important for meaningful ratio comparisons.",
      format_type: :text, display_order: 1, icon: "category"

    register :exchange,
      category: :identity, display_name: "Exchange",
      short_desc: "Stock exchange where the asset trades",
      context_guidance: "The primary exchange for this security. Exchange determines trading hours and regulatory framework.",
      format_type: :text, display_order: 2, icon: "language"

    register :shares_outstanding,
      category: :identity, display_name: "Shares Outstanding",
      short_desc: "Total shares currently held by all shareholders",
      context_guidance: "Used to calculate market cap and per-share metrics. Changes may indicate buybacks or dilution.",
      format_type: :number, display_order: 3, icon: "confirmation_number"

    # ── Crypto Market ────────────────────────────────────────
    register :circulating_supply,
      category: :crypto_market, display_name: "Circulating Supply",
      short_desc: "Coins currently in circulation",
      context_guidance: "The number of coins publicly available and circulating. Compare to max supply to understand scarcity.",
      format_type: :number, display_order: 1, icon: "toll"

    register :total_supply,
      category: :crypto_market, display_name: "Total Supply",
      short_desc: "Total coins that exist (including locked/reserved)",
      context_guidance: "Includes all minted coins. Difference from circulating supply indicates locked, staked, or reserved tokens.",
      format_type: :number, display_order: 2, icon: "database"

    register :fully_diluted_valuation,
      category: :crypto_market, display_name: "FDV",
      short_desc: "Fully Diluted Valuation",
      context_guidance: "Market cap if all possible tokens were in circulation. Large FDV vs market cap gap may indicate future dilution risk.",
      format_type: :currency, display_order: 3, icon: "account_balance_wallet"

    register :total_volume_24h,
      category: :crypto_market, display_name: "24h Volume",
      short_desc: "Total trading volume in the last 24 hours",
      context_guidance: "High volume indicates active trading and liquidity. Low volume may result in larger price swings.",
      format_type: :currency, display_order: 4, icon: "bar_chart"

    register :ath_price,
      category: :crypto_market, display_name: "All-Time High",
      short_desc: "Highest price ever recorded",
      context_guidance: "Reference point for historical peak. Distance from ATH can indicate recovery potential or overvaluation.",
      format_type: :currency, display_order: 5, icon: "emoji_events"

    register :volume_market_cap_ratio,
      category: :crypto_market, display_name: "Vol / Market Cap",
      short_desc: "24h volume relative to market cap",
      context_guidance: "Liquidity indicator. Higher ratios suggest more active trading relative to asset size. Typical range: 1-10%.",
      format_type: :percentage, display_order: 6, icon: "swap_horiz"
    end
  end
end
