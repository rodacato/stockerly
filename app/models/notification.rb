class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, { alert_triggered: 0, earnings_reminder: 1, system: 2 }

  validates :title, presence: true

  scope :unread,  -> { where(read: false) }
  scope :recent,  -> { order(created_at: :desc).limit(20) }

  def mark_as_read!
    update!(read: true)
  end
end
