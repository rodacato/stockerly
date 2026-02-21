FactoryBot.define do
  factory :remember_token do
    user
    token_digest { Digest::SHA256.hexdigest(SecureRandom.urlsafe_base64(32)) }
    expires_at { 30.days.from_now }
    ip_address { "127.0.0.1" }
    user_agent { "RSpec Test Agent" }

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
