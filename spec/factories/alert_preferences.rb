FactoryBot.define do
  factory :alert_preference do
    user
    browser_push { true }
    email_digest { true }
    sms_notifications { false }
  end
end
