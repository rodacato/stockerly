# Triggers an initial price sync when a new asset is created by an admin.
# Runs asynchronously so the asset creation response is not delayed.
class SyncAssetOnCreation
  def self.async? = true

  def self.call(event)
    asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
    SyncSingleAssetJob.perform_later(asset_id)
  end
end
