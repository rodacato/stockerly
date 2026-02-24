FactoryBot.define do
  factory :user do
    full_name { "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :user }
    status { :active }

    trait :admin do
      role { :admin }
    end

    trait :suspended do
      status { :suspended }
    end

    trait :verified do
      is_verified { true }
    end

    trait :email_verified do
      email_verified_at { Time.current }
    end
  end
end
