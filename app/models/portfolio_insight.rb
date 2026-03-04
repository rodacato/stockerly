class PortfolioInsight < ApplicationRecord
  belongs_to :user

  validates :summary, presence: true

  scope :latest, -> { order(generated_at: :desc) }
  scope :recent, -> { where("generated_at >= ?", 7.days.ago) }
end
