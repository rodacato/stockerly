class RememberToken < ApplicationRecord
  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def touch_last_used!
    update!(last_used_at: Time.current)
  end

  def self.generate(user, ip_address:, user_agent:)
    raw_token = SecureRandom.urlsafe_base64(32)
    token = user.remember_tokens.create!(
      token_digest: Digest::SHA256.hexdigest(raw_token),
      expires_at: 30.days.from_now,
      ip_address: ip_address,
      user_agent: user_agent.to_s.first(255)
    )
    [token, raw_token]
  end
end
