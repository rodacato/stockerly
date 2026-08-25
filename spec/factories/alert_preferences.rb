FactoryBot.define do
  factory :alert_preference do
    user
    email_digest { true }
    urgent_email { false }
  end
end
