module MarketData
  module Handlers
    class BroadcastPriceUpdate
      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        asset = Asset.find_by(id: asset_id)
        return unless asset

        Turbo::StreamsChannel.broadcast_replace_to(
          "asset_#{asset.id}",
          target: "asset_price_#{asset.id}",
          partial: "components/asset_price",
          locals: { asset: asset }
        )
      end
    end
  end
end
