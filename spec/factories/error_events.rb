FactoryBot.define do
  factory :error_event do
    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
    exception_class { "ArgumentError" }
    message { "boom" }
    app_line { "app/models/thing.rb:12:in `call'" }
    backtrace { [ "app/models/thing.rb:12:in `call'" ] }
    source { "request" }
    sequence(:reference) { |n| "req-#{n}" }
    request_method { "GET" }
    request_path { "/portfolio" }
    request_params { {} }
    occurrences { 1 }
    first_seen_at { Time.current }
    last_seen_at { Time.current }

    trait :job do
      source { "job" }
      request_method { nil }
      request_path { nil }
      job_class { "SyncNewsJob" }
    end

    trait :stale do
      last_seen_at { (ErrorEvent::RETENTION + 1.day).ago }
    end
  end
end
