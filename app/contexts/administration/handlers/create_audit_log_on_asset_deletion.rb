module Administration
  module Handlers
    # Audit: admin deleted a tracked asset. The asset row is gone by
    # the time this handler runs, so we store the symbol in
    # changes_data instead of using a polymorphic auditable reference.
    class CreateAuditLogOnAssetDeletion
      def self.call(event)
        AuditLog.create!(
          user_id: event.admin_id,
          action: "asset_deleted",
          changes_data: { asset_symbol: event.asset_symbol }
        )
      end
    end
  end
end
