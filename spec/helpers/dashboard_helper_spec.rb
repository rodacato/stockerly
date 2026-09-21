require "rails_helper"

RSpec.describe DashboardHelper, type: :helper do
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
