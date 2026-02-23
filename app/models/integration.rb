class Integration < ApplicationRecord
  enum :connection_status, { connected: 0, syncing: 1, disconnected: 2 }

  validates :provider_name, presence: true, uniqueness: true
  validates :provider_type, presence: true
  validates :api_key_encrypted, presence: true, if: :requires_api_key?

  encrypts :api_key_encrypted

  def masked_api_key
    return nil unless api_key_encrypted.present?
    "••••••••••••#{api_key_encrypted.last(4)}"
  end
end
