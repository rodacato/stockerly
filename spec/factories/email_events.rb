FactoryBot.define do
  factory :email_event do
    email       { "amigo@example.com" }
    event_type  { "delivered" }
    message_id  { "msg_#{SecureRandom.hex(6)}" }
    occurred_at { Time.current }
    raw_payload { {} }

    trait :sent       do event_type { "sent" }      end
    trait :delivered  do event_type { "delivered" } end
    trait :bounced    do event_type { "bounced" }   end
    trait :complained do event_type { "complained" } end
    trait :opened     do event_type { "opened" }    end
    trait :clicked    do event_type { "clicked" }   end
  end
end
