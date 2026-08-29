module Trading
  module UseCases
    # The Activos tab (D9): two of the three tiers, the two daily questions.
    # Tracked is its own screen because it is a budget, not a peer tab.
    class LoadAssets < SimpleUseCase
      TABS = %w[cartera watchlist].freeze

      def call(user:, tab: nil)
        tab = TABS.include?(tab) ? tab : TABS.first
        portfolio = user.portfolio
        currency = user.preferred_currency

        summary = consolidated_summary(portfolio, currency)
        gaps = tab == "watchlist" ? watchlist_gaps(user) : {}

        {
          tab: tab,
          currency: currency,
          portfolio: portfolio,
          summary: summary,
          fx_unavailable: portfolio.present? && summary.nil?,
          positions: (tab == "cartera" ? positions_for(portfolio, currency) : []),
          watchlist_items: (tab == "watchlist" ? watchlist_for(user, gaps) : []),
          watchlist_gaps: gaps
        }
      end

      private

      # Portfolio#convert fails loud on a missing rate — correct for a
      # calculation, wrong for a screen, where it means a 500 instead of your
      # holdings. Consolidation is what becomes impossible, not the list: the
      # rows fall back to their own currency (D10) and the screen says so.
      def consolidated_summary(portfolio, currency)
        return nil unless portfolio

        summary = Trading::Domain::PortfolioSummary.new(portfolio, currency: currency)
        summary.total_value
        summary
      rescue Trading::Domain::MissingFxRate
        nil
      end

      # D68: market value descending, in the declared currency.
      def positions_for(portfolio, currency)
        return [] unless portfolio

        positions = portfolio.open_positions.includes(:asset).to_a
        by_market_value(positions, portfolio, currency) || positions.sort_by { |position| position.asset.symbol }
      end

      # One unreachable rate invalidates the comparison for every row, not only
      # its own, so the whole list retreats to alphabetical rather than mixing.
      def by_market_value(positions, portfolio, currency)
        positions.sort_by do |position|
          asset = position.asset
          [ -portfolio.convert(position.market_value, from: asset.currency, to: currency), asset.symbol ]
        end
      rescue Trading::Domain::MissingFxRate
        nil
      end

      # D68: the watchlist is a queue — what sits closest to its own threshold
      # rises. Distance is a percentage because D10 leaves the prices unconverted.
      def watchlist_for(user, gaps)
        user.watchlist_items
            .includes(:asset)
            .to_a
            .sort_by { |item| proximity_key(item.asset, gaps) }
      end

      # The distance the list is ordered by, keyed by symbol so the row can show
      # the number it is ranked on. An order the reader cannot see is a guess.
      def watchlist_gaps(user)
        thresholds = thresholds_by_symbol(user)

        user.watchlist_items.includes(:asset).each_with_object({}) do |item, gaps|
          distance = nearest_distance(item.asset.current_price, thresholds[item.asset.symbol])
          gaps[item.asset.symbol] = distance if distance
        end
      end

      def thresholds_by_symbol(user)
        user.alert_rules
            .active
            .where(condition: AlertRule::PRICE_THRESHOLD_CONDITIONS)
            .where.not(threshold_value: nil)
            .pluck(:asset_symbol, :threshold_value)
            .group_by(&:first)
            .transform_values { |rows| rows.map(&:last) }
      end

      # A row with a threshold sorts ahead of a row without one: a distance to
      # your own number and a day's movement do not share an axis.
      def proximity_key(asset, gaps)
        symbol = asset.symbol
        distance = gaps[symbol]
        return [ 0, distance, symbol ] if distance

        [ 1, -asset.change_percent_24h.to_f.abs, symbol ]
      end

      def nearest_distance(price, thresholds)
        return nil if price.blank? || price.zero? || thresholds.blank?

        thresholds.map { |threshold| ((threshold - price) / price * 100).abs }.min
      end
    end
  end
end
