class SiteConfigChange < ApplicationRecord
  belongs_to :admin, class_name: "User"

  validates :key, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
