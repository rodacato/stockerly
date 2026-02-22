FactoryBot.define do
  factory :audit_log do
    user
    action { "admin.users.suspend" }
    ip_address { "127.0.0.1" }
  end
end
