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

    it "leaves a difference that prints as zero unsigned too" do
      expect(helper.signed_points(0.04)).to eq("0.0 pts")
      expect(helper.signed_points(-0.04)).to eq("0.0 pts")
    end
  end

  describe "#comparison_standing" do
    it "splits ahead, behind and level on what the card prints" do
      expect(helper.comparison_standing(0.1)).to eq(:ahead)
      expect(helper.comparison_standing(-0.1)).to eq(:behind)
      expect(helper.comparison_standing(0)).to eq(:level)
      expect(helper.comparison_standing(BigDecimal("0.049"))).to eq(:level)
    end
  end

  describe "#comparison_chip" do
    it "paints a lead green and a lag red" do
      expect(helper.comparison_chip(:ahead, "Igual")).to eq([ "bg-positive-bg text-positive-fg", "vas arriba" ])
      expect(helper.comparison_chip(:behind, "Igual")).to eq([ "bg-negative-bg text-negative-fg", "vas abajo" ])
    end

    it "gives a tie its own label and a neutral pair that never carries the positive classes" do
      classes, text = helper.comparison_chip(:level, "Igual")

      expect(text).to eq("Igual")
      expect(classes).to eq("bg-bg-muted text-fg-default")
      expect(classes).not_to include("positive")
      expect(classes).not_to include("negative")
    end
  end
end
