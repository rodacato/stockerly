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

    # Enrolled with a known secret so a spec can mint a valid code.
    trait :with_totp do
      otp_secret { "JBSWY3DPEHPK3PXP" }
      otp_enrolled_at { Time.current }

      transient { recovery_codes { %w[7f2a-91c4 b8d3-4e07] } }

      after(:create) do |user, evaluator|
        evaluator.recovery_codes.each do |code|
          user.otp_recovery_codes.create!(code_digest: Identity::Domain::RecoveryCodes.digest(code))
        end
      end
    end
  end
end
