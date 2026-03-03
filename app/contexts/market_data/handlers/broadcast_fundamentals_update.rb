module MarketData
  module Handlers
    class BroadcastFundamentalsUpdate
      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        asset = Asset.find_by(id: asset_id)
        return unless asset

        Turbo::StreamsChannel.broadcast_replace_to(
          "asset_#{asset.id}",
          target: "asset_fundamentals_#{asset.id}",
          partial: "components/asset_fundamentals",
          locals: { asset: asset }
        )
      rescue ActionView::MissingTemplate
        # Partial not yet created (Phase 10.2) — safe to skip
      end
    end
  end
end
