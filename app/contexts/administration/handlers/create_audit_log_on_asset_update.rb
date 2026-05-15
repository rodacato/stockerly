module Administration
  module Handlers
    # Audit: admin edited a tracked asset. The diff lives in
    # event.changes ({field => {from:, to:}}); we store it under
    # changes_data along with the symbol for log readability. If the
    # asset has been deleted between publish and handle (rare), we
    # skip the audit row — auditable would be dangling.
    class CreateAuditLogOnAssetUpdate
      def self.call(event)
        asset = Asset.find_by(id: event.asset_id)
        return unless asset

        AuditLog.create!(
          user_id: event.admin_id,
          action: "asset_updated",
          auditable: asset,
          changes_data: { symbol: event.symbol, changes: event.changes }
        )
      end
    end
  end
end
