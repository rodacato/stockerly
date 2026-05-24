class InviteCode < ApplicationRecord
  EXPIRATION_WINDOW = 7.days

  belongs_to :used_by_user, class_name: "User", optional: true
  belongs_to :created_by_user, class_name: "User"

  validates :code, presence: true, uniqueness: true
  validates :code, format: { with: /\A[a-f0-9]{12}\z/, message: "must be 12 hex characters" }
  validates :expires_at, presence: true

  scope :unused,  -> { where(used_at: nil) }
  scope :used,    -> { where.not(used_at: nil) }
  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :active,  -> { unused.where("expires_at >= ?", Time.current) }

  before_validation :normalize_code
  before_validation :set_default_expires_at, on: :create

  def self.normalize(input)
    return nil if input.nil?

    input.to_s.gsub(/[\s\-_]/, "").downcase
  end

  def self.generate_code
    SecureRandom.hex(6)
  end

  def used?
    used_at.present?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def redeemable?
    !used? && !expired?
  end

  def formatted_code
    code.scan(/.{1,4}/).join("-")
  end

  private

  def normalize_code
    self.code = self.class.normalize(code) if code.present?
  end

  def set_default_expires_at
    self.expires_at ||= Time.current + EXPIRATION_WINDOW
  end
end
