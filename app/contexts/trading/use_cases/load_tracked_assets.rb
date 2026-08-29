module Trading
  module UseCases
    # Tracked — the third tier (D9). Not a peer tab: it is where the daily
    # sync budget is visible and where syncing can be paused. Absorbs the list
    # /admin/assets used to show, minus the admin costume (D5).
    class LoadTrackedAssets < SimpleUseCase
      def call(user:, query: nil)
        held = (user.portfolio&.open_positions&.pluck(:asset_id) || []).to_set
        followed = user.watchlist_items.pluck(:asset_id).to_set

        {
          assets: filtered(query),
          total: Asset.count,
          held_ids: held,
          followed_ids: followed,
          tier_counts: tier_counts(held, followed),
          budget: MarketData::Domain::FundamentalsBudget.today
        }
      end

      private

      def filtered(query)
        scope = Asset.order(:symbol)
        return scope if query.blank?

        scope.where("symbol ILIKE :q OR name ILIKE :q", q: "%#{query.strip}%")
      end

      # Counted over the assets that can actually spend this budget, not over
      # the whole list: SyncAllFundamentalsJob only enqueues active stocks and
      # ETFs, so counting crypto and fixed income here would credit them with
      # calls they never make.
      def tier_counts(held, followed)
        eligible = Asset.where(asset_type: [ :stock, :etf ], sync_status: :active).pluck(:id)

        {
          held: eligible.count { |id| held.include?(id) },
          followed: eligible.count { |id| !held.include?(id) && followed.include?(id) },
          tracked: eligible.count { |id| !held.include?(id) && !followed.include?(id) }
        }
      end
    end
  end
end
