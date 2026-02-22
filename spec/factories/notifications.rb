FactoryBot.define do
  factory :notification do
    user
    title { "Alert triggered" }
    notification_type { :alert_triggered }
    read { false }
  end
end
