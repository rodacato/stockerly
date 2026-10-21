# What the owner meant to hold: a target share per kind of asset and a monthly
# contribution in MXN. The app only compares against it; it never proposes one.
class Plan < ApplicationRecord
  SHARES = %i[stocks_share crypto_share fixed_income_share].freeze

  belongs_to :portfolio

  validates(*SHARES, numericality: { only_integer: true, in: 0..100 })
  validates :monthly_contribution, numericality: { greater_than_or_equal_to: 0 }
  validate :shares_sum_to_one_hundred

  def shares = SHARES.index_with { |share| public_send(share) }

  private

  def shares_sum_to_one_hundred
    return unless SHARES.all? { |share| public_send(share).is_a?(Integer) }

    errors.add(:base, :shares_must_sum) unless shares.values.sum == 100
  end
end
