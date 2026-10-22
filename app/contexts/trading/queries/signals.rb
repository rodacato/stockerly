module Trading
  module Queries
    # Public read API (ADR-031): the Señales screen's list as plain data, with
    # its window and limit. What is held is left out unless the caller may
    # say what the owner holds; then each reading says whether it is held.
    class Signals
      def self.call(include_held:, user: User.first)
        return [] unless user

        held = user.portfolio&.open_positions&.pluck(:asset_id) || []
        watched = user.watchlist_items.pluck(:asset_id)
        ids = include_held ? (held + watched).uniq : watched - held
        held_symbols = include_held ? user.portfolio&.open_positions&.joins(:asset)&.pluck("assets.symbol").to_a : []

        MarketData::Queries::NotableObservations.readings(asset_ids: ids, limit: UseCases::LoadSignals::LIMIT,
                                                          window_days: UseCases::LoadSignals::WINDOW_DAYS)
                                                .map { |reading| reading.merge(held: held_symbols.include?(reading[:symbol])) }
      end
    end
  end
end
