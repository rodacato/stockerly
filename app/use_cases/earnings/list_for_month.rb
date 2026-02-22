module Earnings
  class ListForMonth < ApplicationUseCase
    def call(user:, date: Date.current, filter: nil)
      watchlist_asset_ids = user.watchlist_items.pluck(:asset_id)

      scope = EarningsEvent.for_month(date).includes(:asset)
      scope = scope.where(asset_id: watchlist_asset_ids) if filter == "watchlist"

      watchlist_events = EarningsEvent.for_month(date)
                           .where(asset_id: watchlist_asset_ids)
                           .includes(:asset)
                           .order(:report_date)

      Success({
        events: scope.order(:report_date),
        date: date,
        watchlist_events: watchlist_events
      })
    end
  end
end
