require "rails_helper"

RSpec.describe "I18n fallback chain" do
  it "falls back from es-MX to Rails' built-in en for framework keys" do
    expect(I18n.fallbacks[:"es-MX"]).to end_with(:en)
  end

  it "resolves a framework key es-MX does not override from en" do
    expect(I18n.t("errors.messages.blank", locale: :"es-MX")).to be_present
  end

  it "is declared once, so no environment file overrides application.rb" do
    overriding = Rails.root.glob("config/environments/*.rb").select do |file|
      File.read(file).match?(/^\s*config\.i18n\.fallbacks\b/)
    end

    expect(overriding).to be_empty
  end
end
