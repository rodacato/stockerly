class TrendScore < ApplicationRecord
  belongs_to :asset

  enum :label, {
    low_score: 0, low_moderate: 1, neutral: 2,
    moderate: 3, high_score: 4, peak: 5
  }
  enum :direction, { upward: 0, downward: 1 }

  validates :score, presence: true, inclusion: { in: 0..100 }

  scope :latest, -> { order(calculated_at: :desc) }

  def factor_breakdown
    (factors.presence || {}).with_indifferent_access
  end
end
