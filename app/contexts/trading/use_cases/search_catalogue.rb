module Trading
  module UseCases
    # The catalogue half of search (D125): what the instance already tracks,
    # answered without a provider call, each result on its D9 tier.
    class SearchCatalogue < SimpleUseCase
      LIMIT = 8
      MIN_LENGTH = 2
      TIER_ORDER = { held: 0, followed: 1, tracked: 2 }.freeze

      def call(user:, query:)
        query = query.to_s.strip
        return [] if query.length < MIN_LENGTH

        held = (user.portfolio&.open_positions&.pluck(:asset_id) || []).to_set
        followed = user.watchlist_items.pluck(:asset_id).to_set

        results = matching(query).map { |asset| { asset: asset, tier: tier_for(asset, held, followed) } }
        results = results.sort_by { |r| rank(r, query) }.first(LIMIT)

        day_changes = MarketData::Domain::DayChange.by_asset(
          MarketData::Queries::PriceSeries.recent_closes(results.pluck(:asset), points: 2)
        )
        results.each { |r| r[:change] = day_changes[r[:asset].id] }
      end

      private

      def matching(query)
        pattern = "%#{Asset.sanitize_sql_like(query)}%"
        Asset.where("symbol ILIKE :p OR name ILIKE :p", p: pattern).to_a
      end

      def tier_for(asset, held, followed)
        return :held if held.include?(asset.id)
        return :followed if followed.include?(asset.id)

        :tracked
      end

      def rank(result, query)
        exact = result[:asset].symbol.casecmp?(query) ? 0 : 1
        [ exact, TIER_ORDER.fetch(result[:tier]), result[:asset].symbol ]
      end
    end
  end
end
