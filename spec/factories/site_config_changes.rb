FactoryBot.define do
  factory :site_config_change do
    association :admin, factory: %i[user admin]
    key { "registration_open" }
    old_value { "false" }
    new_value { "true" }
  end
end
