class MigrateIntegrationKeysToPool < ActiveRecord::Migration[8.1]
  def up
    Integration.where.not(api_key_encrypted: nil).find_each do |integration|
      next if integration.api_key_pools.where(is_default: true).exists?

      legacy_key = integration.api_key_encrypted
      next if legacy_key.blank?

      integration.api_key_pools.create!(
        name: "Default",
        api_key_encrypted: legacy_key,
        is_default: true,
        enabled: true
      )
    end
  end

  def down
    ApiKeyPool.where(is_default: true, name: "Default").find_each do |pool_key|
      pool_key.integration.update_column(:api_key_encrypted, pool_key.api_key_encrypted)
    end
    ApiKeyPool.where(is_default: true, name: "Default").destroy_all
  end
end
