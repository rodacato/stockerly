require "rails_helper"

RSpec.describe DashboardHelper, type: :helper do
  describe "#dashboard_greeting" do
    it "returns 'Buenos días' between 05:00 and 11:59" do
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 5, 0))).to eq("Buenos días")
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 11, 59))).to eq("Buenos días")
    end

    it "returns 'Buenas tardes' between 12:00 and 18:59" do
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 12, 0))).to eq("Buenas tardes")
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 18, 59))).to eq("Buenas tardes")
    end

    it "returns 'Buenas noches' between 19:00 and 04:59" do
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 19, 0))).to eq("Buenas noches")
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 23, 59))).to eq("Buenas noches")
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 0, 0))).to eq("Buenas noches")
      expect(helper.dashboard_greeting(Time.zone.local(2026, 5, 19, 4, 59))).to eq("Buenas noches")
    end
  end

  describe "#first_name_of" do
    it "extracts the first token of full_name" do
      user = build(:user, full_name: "Adrian Castillo", email: "adrian@test.com")
      expect(helper.first_name_of(user)).to eq("Adrian")
    end

    it "falls back to email local-part when full_name is blank" do
      user = build(:user, full_name: "", email: "andres@test.com")
      expect(helper.first_name_of(user)).to eq("andres")
    end
  end
end
