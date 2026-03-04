class ApiKeyPool < ApplicationRecord
  encrypts :api_key_encrypted

  belongs_to :integration

  validates :api_key_encrypted, presence: true
  validates :name, presence: true
  validate :only_one_default_per_integration, if: :is_default?

  scope :enabled, -> { where(enabled: true) }
  scope :least_used, -> { order(:daily_calls) }
  scope :default_key, -> { where(is_default: true) }

  def masked_api_key
    return nil unless api_key_encrypted.present?
    "••••••••••••#{api_key_encrypted.last(4)}"
  end

  private

  def only_one_default_per_integration
    existing = self.class.where(integration_id: integration_id, is_default: true)
    existing = existing.where.not(id: id) if persisted?
    errors.add(:is_default, "another default key already exists for this integration") if existing.exists?
  end
end
