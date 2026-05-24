FactoryBot.define do
  factory :user_activity do
    user
    action { "page_view:dashboard#show" }
    params { { "controller" => "dashboard", "action" => "show" } }
    occurred_at { Time.current }
  end
end
