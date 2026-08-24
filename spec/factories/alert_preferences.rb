FactoryBot.define do
  factory :alert_preference do
    user
    browser_push { true }
    email_digest { true }
    urgent_email { false }
  end
end
