FactoryBot.define do
  factory :invite_code do
    code { SecureRandom.hex(6) }
    note { nil }
    used_at { nil }
    used_by_user { nil }
    association :created_by_user, factory: %i[user admin]

    trait :used do
      used_at { Time.current }
      association :used_by_user, factory: :user
    end
  end
end
