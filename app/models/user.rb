class User < ApplicationRecord
  has_secure_password

  # The shared secret is the whole factor: anyone who reads it can mint valid
  # codes forever, so it never sits in the clear (ADR-018).
  encrypts :otp_secret

  # --- Enums ---
  enum :role, { user: 0, admin: 1 }

  # --- Associations ---
  has_one  :portfolio,        dependent: :destroy
  has_one  :alert_preference, dependent: :destroy
  has_many :watchlist_items,   dependent: :destroy
  has_many :watched_assets,    through: :watchlist_items, source: :asset
  has_many :alert_rules,       dependent: :destroy
  has_many :alert_events,      dependent: :destroy
  has_many :notifications,     dependent: :destroy
  # The audit trail goes with the account: both columns are `null: false`
  # behind foreign keys, so there is no nullify to fall back on.
  has_many :audit_logs, dependent: :destroy
  has_many :site_config_changes, foreign_key: :admin_id, inverse_of: :admin, dependent: :destroy
  has_many :otp_recovery_codes, dependent: :destroy

  # --- Validations ---
  validates :full_name, presence: true, length: { minimum: 2 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password_digest_changed? }

  # --- Scopes ---
  scope :admins, -> { where(role: :admin) }

  def onboarded?
    onboarded_at.present?
  end

  # Enrolment is finished, not merely started: a secret exists on the record
  # between "show me the QR" and "here is my first code", and a half-enrolled
  # account must still log in with the password alone.
  def otp_enrolled?
    otp_enrolled_at.present?
  end

  def unused_recovery_codes_count
    otp_recovery_codes.unconsumed.count
  end

  # --- Callbacks ---
  before_validation :downcase_email

  # Override Rails 8 default (15 min). Single source of truth for the
  # password-reset link lifetime — referenced by the mailer body, the
  # views' "el enlace expira en X" hint, and any operational tooling.
  PASSWORD_RESET_EXPIRES_IN = 2.hours

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_EXPIRES_IN do
    password_salt&.last(10)
  end

  private

  def downcase_email
    self.email = email&.downcase&.strip
  end
end
