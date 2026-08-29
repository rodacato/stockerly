module MarketData
  module Handlers
    # Swaps the fundamentals block in when a sync lands, so a reader who asked
    # for it sees it arrive instead of learning to reload.
    class BroadcastFundamentalsUpdate
      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        asset = Asset.find_by(id: asset_id)
        return unless asset

        fundamental = asset.asset_fundamentals.where(period_label: "CALCULATED").latest.first ||
                      asset.asset_fundamentals.overview.latest.first

        Turbo::StreamsChannel.broadcast_replace_to(
          "asset_#{asset.id}",
          target: "asset_fundamentals_#{asset.id}",
          partial: "market/fundamentals_block",
          locals: { asset: asset, presenter: Domain::FundamentalPresenter.new(asset: asset, fundamental: fundamental),
                    has_fundamentals: fundamental.present?, pending: false }
        )
      end
    end
  end
end
