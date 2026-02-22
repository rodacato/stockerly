FactoryBot.define do
  factory :system_log do
    task_name { "price_sync" }
    module_name { "Finance" }
    severity { :success }
    duration_seconds { 2.5 }

    trait :error do
      severity { :error }
      error_message { "Connection timeout" }
    end

    trait :warning do
      severity { :warning }
    end
  end
end
