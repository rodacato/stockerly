module Trading
  module Handlers
    class RecordWatchlistItemAddedActivity
      def self.call(event)
        user_id      = event.is_a?(Hash) ? event[:user_id] : event.user_id
        asset_symbol = event.is_a?(Hash) ? event[:asset_symbol] : event.asset_symbol

        ActivityRecorder.call(
          user:   User.find_by(id: user_id),
          action: "watchlist_item_added",
          params: { asset_symbol: asset_symbol.to_s }
        )
      end
    end
  end
end
