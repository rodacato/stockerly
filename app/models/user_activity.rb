class UserActivity < ApplicationRecord
  belongs_to :user

  validates :action, presence: true
  validates :occurred_at, presence: true

  scope :recent,    -> { order(occurred_at: :desc) }
  scope :by_action, ->(name) { where(action: name) if name.present? }
end
