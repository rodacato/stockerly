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

    it "falls back to email local-part when full_name is nil" do
      user = build(:user, full_name: nil, email: "andres@test.com")
      expect(helper.first_name_of(user)).to eq("andres")
    end
  end

  describe "#signed_points" do
    it "marks a lead with a plus and a lag with the typographic minus" do
      expect(helper.signed_points(2.4)).to eq("+2.4 pts")
      expect(helper.signed_points(-2.4)).to eq("−2.4 pts")
    end

    it "leaves a tie unsigned, because neither side is ahead" do
      expect(helper.signed_points(0)).to eq("0.0 pts")
    end
  end
end
