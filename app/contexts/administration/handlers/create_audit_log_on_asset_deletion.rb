module Administration
  module Handlers
    # Audit: admin deleted a tracked asset. The asset row is gone by
    # the time this handler runs, so we store the symbol in
    # changes_data instead of using a polymorphic auditable reference.
    # The key is `symbol` to match the asset_updated audit log shape
    # (consistent unified-view across asset audit actions).
    class CreateAuditLogOnAssetDeletion
      def self.call(event)
        AuditLog.create!(
          user_id: event.admin_id,
          action: "asset_deleted",
          changes_data: { symbol: event.asset_symbol }
        )
      end
    end
  end
end
