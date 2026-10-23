require "rails_helper"

# ADR-032: the usage record's one reader, and the switch behind it.
RSpec.describe "Admin · Uso", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { create(:user, :admin, onboarded_at: Time.current) }

  before { login_as(admin) }

  it "is off by default, says so once, and still shows the day counters" do
    3.times { AppOpen.record(path: "/dashboard") }

    get admin_usage_path

    expect(response.body).to include(I18n.t("admin.usage.show.ajustes"), I18n.t("admin.usage.show.pantallas.dashboard"))
    expect(response.body).to include(I18n.t("admin.usage.show.panorama_por_dia"), ">3<")
    expect(response.body.scan(%r{\d{1,2}/\d{2}</span>}).size).to eq(Usage::Queries::Report::OPEN_DAYS)
    expect(response.body).not_to include(I18n.t("admin.usage.show.embudos"), I18n.t("admin.usage.show.sin_datos"))
  end

  # D31 gave Descubrir a kill criterion with a date; it is read here, not in a console.
  it "shows how many of the last weeks Descubrir was opened in" do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    MarketData::Discover::VisitLog.record

    get admin_usage_path

    expect(response.body).to include("Descubrir se vio 1 de las últimas 8 semanas.")
  end

  it "reads a week the switch was off as unmeasured, never as zero" do
    get admin_usage_path

    expect(response.body).not_to match(%r{tabular-nums[^"]*">0</td>})
  end

  it "says when it was turned on, and measures only from then" do
    travel_to(Time.zone.local(2026, 10, 22, 12)) do
      SiteConfig.set(Usage::SWITCH, true)

      get admin_usage_path

      expect(response.body).to include(I18n.t("admin.usage.show.encendido", fecha: "22 oct"))
      expect(response.body.scan(I18n.t("admin.usage.show.sin_datos")).size).to eq(4)
      expect(response.body).to match(%r{tabular-nums[^"]*">0</td>})
    end
  end

  it "asks each catalogued event's question in the owner's words" do
    get admin_usage_path

    Usage::Domain::Catalogue::EVENTS.each_key do |name|
      expect(response.body).to include(ERB::Util.h(I18n.t("admin.usage.show.preguntas.#{name.tr(".", "_")}", raise: true)))
    end
  end

  it "leads a funnel with this week's counts, and keeps a percentage for when there are enough" do
    SiteConfig.set(Usage::SWITCH, true)
    2.times { Usage.record("rule_suggestion.shown", condition: "day_change_percent") }
    Usage.record("rule.created", via: "rule_suggestion")

    get admin_usage_path

    expect(response.body).to include(I18n.t("admin.usage.show.de", taken: 1, offered: 2))
    expect(response.body).not_to include("50%")
  end

  it "says an action came from an earlier week's offer rather than hiding it" do
    SiteConfig.set(Usage::SWITCH, true)
    UsageEvent.create!(name: "rule_suggestion.shown", occurred_at: 1.week.ago, properties: {})
    Usage.record("rule.created", via: "rule_suggestion")

    get admin_usage_path

    expect(response.body).to include(I18n.t("admin.usage.show.esta_semana_sin_oferta", count: 1))
  end

  it "counts its own opening, which is what decides whether it is kept" do
    expect { get admin_usage_path }.to change { AppOpen.where(path: "/admin/usage").sum(:count) }.by(1)
  end

  it "is turned on from the instance's settings, and recorded as a change" do
    patch admin_settings_path, params: { usage_tracking: "1" }

    expect(Usage.enabled?).to be(true)
    expect(SiteConfigChange.last).to have_attributes(key: "usage_tracking", new_value: "true")
  end

  it "has a row in Ajustes that says when it is off" do
    get settings_path

    expect(response.body).to include(admin_usage_path, I18n.t("settings.show.uso"), I18n.t("settings.show.uso_apagado"))

    SiteConfig.set(Usage::SWITCH, true)
    get settings_path

    expect(response.body).not_to include(I18n.t("settings.show.uso_apagado"))
  end
end
