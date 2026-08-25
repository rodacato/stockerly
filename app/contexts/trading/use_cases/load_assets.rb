module Trading
  module UseCases
    # The Activos tab (D9): two of the three tiers, the two daily questions.
    # Rastreados is its own screen because it is a budget, not a peer tab.
    class LoadAssets < SimpleUseCase
      TABS = %w[cartera sigo].freeze

      def call(user:, tab: nil)
        tab = TABS.include?(tab) ? tab : TABS.first
        portfolio = user.portfolio

        summary = consolidated_summary(portfolio, user.preferred_currency)

        {
          tab: tab,
          currency: user.preferred_currency,
          portfolio: portfolio,
          summary: summary,
          fx_unavailable: portfolio.present? && summary.nil?,
          positions: (tab == "cartera" ? positions_for(portfolio) : []),
          watchlist_items: (tab == "sigo" ? watchlist_for(user) : [])
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

      def positions_for(portfolio)
        return [] unless portfolio

        portfolio.open_positions.includes(:asset).order(:id)
      end

      def watchlist_for(user)
        user.watchlist_items.includes(:asset).order(created_at: :desc)
      end
    end
  end
end
