class User < ApplicationRecord
  has_secure_password

  # --- Enums ---
  enum :role, { user: 0, admin: 1 }
  enum :status, { active: 0, suspended: 1 }

  # --- Associations ---
  has_one  :portfolio,        dependent: :destroy
  has_one  :alert_preference, dependent: :destroy
  has_many :remember_tokens,  dependent: :destroy
  has_many :watchlist_items,   dependent: :destroy
  has_many :watched_assets,    through: :watchlist_items, source: :asset
  has_many :alert_rules,       dependent: :destroy
  has_many :alert_events,      dependent: :destroy
  has_many :notifications,     dependent: :destroy
  has_many :audit_logs

  # --- Validations ---
  validates :full_name, presence: true, length: { minimum: 2 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password_digest_changed? }

  # --- Scopes ---
  scope :admins,           -> { where(role: :admin) }
  scope :traders,          -> { where(role: :user) }
  scope :not_suspended,    -> { where.not(status: :suspended) }
  scope :email_verified,   -> { where.not(email_verified_at: nil) }
  scope :email_unverified, -> { where(email_verified_at: nil) }

  def onboarded?
    onboarded_at.present?
  end

  def email_verified?
    email_verified_at.present?
  end

  # --- Callbacks ---
  before_validation :downcase_email

  # Override Rails 8 default (15 min) to 2 hours
  generates_token_for :password_reset, expires_in: 2.hours do
    password_salt&.last(10)
  end

  generates_token_for :email_verification, expires_in: 24.hours do
    email
  end

  private

  def downcase_email
    self.email = email&.downcase&.strip
  end
end
