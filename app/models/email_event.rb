class EmailEvent < ApplicationRecord
  # Event names mirror Resend's webhook types with the "email." prefix stripped.
  # https://resend.com/docs/dashboard/webhooks/event-types
  EVENT_TYPES = %w[sent delivered bounced complained opened clicked].freeze

  validates :email,       presence: true
  validates :event_type,  presence: true, inclusion: { in: EVENT_TYPES }
  validates :occurred_at, presence: true

  scope :for_email,   ->(addr) { where(email: addr.to_s.downcase) }
  scope :for_message, ->(id)   { where(message_id: id) }
  scope :by_type,     ->(t)    { where(event_type: t.to_s) }
  scope :recent,      ->       { order(occurred_at: :desc) }

  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
