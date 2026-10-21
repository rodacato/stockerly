module Trading
  module Domain
    # Whether a quote is current enough to say "nothing needs a look". The
    # short rule behind Asset#price_stale? labels a figure live; it is too
    # strict here, since the market is shut overnight and at weekends and a close
    # is current for a few days. Fixed income syncs weekly, so it has no age to hold.
    class QuoteFreshness
      WINDOW = 4.days

      def self.current?(asset, within: WINDOW)
        return true if asset.asset_type_fixed_income?

        asset.price_updated_at.present? && asset.price_updated_at >= within.ago
      end
    end
  end
end
