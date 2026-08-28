class OtpRecoveryCode < ApplicationRecord
  belongs_to :user

  scope :unconsumed, -> { where(consumed_at: nil) }

  def consumed?
    consumed_at.present?
  end
end
