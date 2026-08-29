FactoryBot.define do
  factory :push_subscription do
    user
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/token-#{n}" }
    p256dh_key { "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM" }
    auth_key { "tBHItJI5svbpez7KI4CCXg" }
  end
end
