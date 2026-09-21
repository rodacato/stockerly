require "rails_helper"

# #541: one percent convention. The sign is the typographic minus, and a
# magnitude carries no sign at all — the copy around it gives the direction.
RSpec.describe AssetsHelper, "percent formatting" do
  describe "#signed_percent" do
    it "marks a rise with a plus" do
      expect(helper.signed_percent(2.35)).to eq("+2.4%")
    end

    it "marks a fall with the typographic minus, not a hyphen" do
      expect(helper.signed_percent(-2.35)).to eq("−2.4%")
      expect(helper.signed_percent(-2.35)).not_to include("-")
    end

    it "reads zero as flat rather than negative" do
      expect(helper.signed_percent(0)).to eq("+0.0%")
    end
  end

  describe "#day_change_direction" do
    it "reads a rise as up and a fall as down" do
      expect(helper.day_change_direction(1.5)).to eq(:up)
      expect(helper.day_change_direction(-1.5)).to eq(:down)
    end

    it "reads a day that did not move as flat, not as a rise" do
      expect(helper.day_change_direction(0)).to eq(:flat)
      expect(helper.day_change_direction(BigDecimal("0"))).to eq(:flat)
    end

    it "reads an unknown day change as flat" do
      expect(helper.day_change_direction(nil)).to eq(:flat)
    end
  end

  describe "#unsigned_percent" do
    it "states a distance without a sign" do
      expect(helper.unsigned_percent(3.21)).to eq("3.2%")
    end

    it "states a negative distance as the magnitude it is" do
      expect(helper.unsigned_percent(-3.21)).to eq("3.2%")
    end
  end
end
