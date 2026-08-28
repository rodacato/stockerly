FactoryBot.define do
  factory :user do
    full_name { "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :user }

    trait :admin do
      role { :admin }
    end
  end
end
