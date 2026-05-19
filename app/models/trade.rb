class Trade < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  belongs_to :position, optional: true

  enum :side, { buy: 0, sell: 1 }

  validates :shares,          presence: true, numericality: { greater_than: 0 }
  validates :price_per_share, presence: true, numericality: { greater_than: 0 }
  validates :total_amount,    presence: true
  validates :executed_at,     presence: true

  before_validation :calculate_total_amount, on: :create

  scope :buys,  -> { where(side: :buy) }
  scope :sells, -> { where(side: :sell) }
  scope :recent, -> { order(executed_at: :desc) }
  scope :kept, -> { where(discarded_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }

  # Trades can be edited or deleted only within MODIFICATION_WINDOW after
  # execution. The same window is enforced inside `UpdateTrade` and
  # `DeleteTrade` use cases (MAX_*_AGE_DAYS constants); this helper is the
  # view-facing predicate so templates don't repeat the time-arithmetic
  # rule. Source of truth for the window value remains in the use cases
  # (they raise the user-facing failure) — this constant is the view-side
  # mirror.
  MODIFICATION_WINDOW = 30.days

  def editable?
    !discarded? && executed_at >= MODIFICATION_WINDOW.ago
  end

  def discarded?
    discarded_at.present?
  end

  def discard!
    update!(discarded_at: Time.current)
  end

  private

  def calculate_total_amount
    self.total_amount = (shares || 0) * (price_per_share || 0)
  end
end
