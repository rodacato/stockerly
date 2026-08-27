module MarketData
  module Handlers
    class BroadcastPriceUpdate
      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        asset = Asset.find_by(id: asset_id)
        return unless asset

        # One account per instance (ADR-0010), and the partial needs it for the
        # approximate line: a broadcast renders outside a request, so there is
        # no current_user to fall back on.
        owner = User.first
        return unless owner

        Turbo::StreamsChannel.broadcast_replace_to(
          "asset_#{asset.id}",
          target: "asset_price_#{asset.id}",
          partial: "components/asset_price",
          locals: { asset: asset, user: owner }
        )
      end
    end
  end
end
