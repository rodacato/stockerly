class ApiKeyPool < ApplicationRecord
  encrypts :api_key_encrypted

  belongs_to :integration

  validates :api_key_encrypted, presence: true
  validates :name, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :least_used, -> { order(:daily_calls) }

  def masked_api_key
    return nil unless api_key_encrypted.present?
    "••••••••••••#{api_key_encrypted.last(4)}"
  end
end
