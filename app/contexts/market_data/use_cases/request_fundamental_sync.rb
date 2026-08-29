module MarketData
  module UseCases
    # Asks for an asset's fundamentals. Returns whether a job was enqueued, so
    # the caller can tell "on its way" from "nothing to do".
    #
    # The cooldown is the reason this is not a bare perform_later: the request
    # comes from a button a reader can press repeatedly.
    class RequestFundamentalSync < SimpleUseCase
      COOLDOWN = 10.minutes

      def call(asset:)
        return false unless asset.asset_type_stock? || asset.asset_type_etf?
        return false if asset.fundamentals_synced_at.present? && asset.fundamentals_synced_at > COOLDOWN.ago

        SyncFundamentalJob.perform_later(asset.id)
        true
      end
    end
  end
end
