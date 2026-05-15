module Administration
  module Handlers
    # Audit: admin edited a tracked asset. The diff lives in
    # event.changes ({field => {from:, to:}}); we store it under
    # changes_data along with the symbol for log readability. If the
    # asset has been deleted between publish and handle (rare race),
    # the audit row is still created — the changes_data carries the
    # full payload; the polymorphic auditable link is optional and
    # remains nil for that edge case.
    class CreateAuditLogOnAssetUpdate
      def self.call(event)
        AuditLog.create!(
          user_id: event.admin_id,
          action: "asset_updated",
          auditable: Asset.find_by(id: event.asset_id),
          changes_data: { symbol: event.symbol, changes: event.changes }
        )
      end
    end
  end
end
