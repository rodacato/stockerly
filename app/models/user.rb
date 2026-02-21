class User < ApplicationRecord
  has_secure_password

  has_many :remember_tokens, dependent: :destroy

  enum :role, { user: 0, admin: 1 }
  enum :status, { active: 0, suspended: 1 }

  validates :full_name, presence: true, length: { minimum: 2 }
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password_digest_changed? }

  before_save :downcase_email

  def generate_password_reset_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(
      password_reset_token: Digest::SHA256.hexdigest(raw_token),
      password_reset_sent_at: Time.current
    )
    raw_token
  end

  def clear_password_reset_token!
    update!(password_reset_token: nil, password_reset_sent_at: nil)
  end

  def password_reset_expired?
    password_reset_sent_at.nil? || password_reset_sent_at < 2.hours.ago
  end

  private

  def downcase_email
    self.email = email.downcase.strip
  end
end
