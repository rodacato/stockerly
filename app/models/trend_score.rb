class TrendScore < ApplicationRecord
  belongs_to :asset

  enum :label, {
    weak: 0, moderate: 1, strong: 2,
    parabolic: 3, sideways: 4, weakening: 5
  }
  enum :direction, { upward: 0, downward: 1 }

  validates :score, presence: true, inclusion: { in: 0..100 }

  scope :latest, -> { order(calculated_at: :desc) }

  def factor_breakdown
    (factors.presence || {}).with_indifferent_access
  end
end
