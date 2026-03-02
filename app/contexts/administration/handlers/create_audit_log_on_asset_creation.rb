module Administration
  class CreateAuditLogOnAssetCreation
    def self.call(event)
      asset = Asset.find_by(id: event.asset_id)
      return unless asset

      AuditLog.create!(
        user_id: event.admin_id,
        action: "asset_created",
        auditable: asset,
        changes_data: { after: { symbol: event.symbol } }
      )
    end
  end
end
