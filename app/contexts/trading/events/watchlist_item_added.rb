module Trading
  module Events
    class WatchlistItemAdded < BaseEvent
      attribute :watchlist_item_id, Types::Integer
      attribute :user_id, Types::Integer
      attribute :asset_symbol, Types::String
    end
  end
end
