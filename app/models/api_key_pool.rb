class ApiKeyPool < ApplicationRecord
  encrypts :api_key_encrypted

  belongs_to :integration

  validates :api_key_encrypted, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :least_used, -> { order(:daily_calls) }
end
