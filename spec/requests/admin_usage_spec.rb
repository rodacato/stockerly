require "rails_helper"

# ADR-032: the usage record's one reader, and the switch behind it.
RSpec.describe "Admin · Uso", type: :request do
  let(:admin) { create(:user, :admin, onboarded_at: Time.current) }

  before { login_as(admin) }

  it "is off by default, says so, and still shows the day counters" do
    AppOpen.record(path: "/dashboard")

    get admin_usage_path

    expect(response.body).to include(I18n.t("admin.usage.show.ajustes"))
    expect(response.body).to include("/dashboard", I18n.t("admin.usage.show.en_14_dias", count: 1))
  end

  it "says a funnel and the capture time have no data rather than showing zero" do
    get admin_usage_path

    expect(response.body.scan(I18n.t("admin.usage.show.sin_datos")).size).to eq(4)
  end

  it "shows a funnel's offers against the actions they led to" do
    SiteConfig.set(Usage::SWITCH, true)
    2.times { Usage.record("rule_suggestion.shown", condition: "day_change_percent") }
    Usage.record("rule.created", via: "rule_suggestion")

    get admin_usage_path

    expect(response.body).to include(I18n.t("admin.usage.show.tomadas", taken: 1, offered: 2, percent: "50.0%"))
  end

  it "counts its own opening, which is what decides whether it is kept" do
    expect { get admin_usage_path }.to change { AppOpen.where(path: "/admin/usage").sum(:count) }.by(1)
  end

  it "is turned on from the instance's settings, and recorded as a change" do
    patch admin_settings_path, params: { usage_tracking: "1" }

    expect(Usage.enabled?).to be(true)
    expect(SiteConfigChange.last).to have_attributes(key: "usage_tracking", new_value: "true")
  end

  it "has a row in Ajustes" do
    get settings_path

    expect(response.body).to include(admin_usage_path, I18n.t("settings.show.uso"))
  end
end
