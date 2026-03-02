require "rails_helper"

RSpec.describe GainLoss do
  describe "#positive?" do
    it "returns true for positive absolute" do
      gl = GainLoss.new(absolute: 100.0, percent: 5.0)
      expect(gl).to be_positive
    end

    it "returns false for negative absolute" do
      gl = GainLoss.new(absolute: -50.0, percent: -2.5)
      expect(gl).not_to be_positive
    end
  end

  describe "#negative?" do
    it "returns true for negative absolute" do
      gl = GainLoss.new(absolute: -50.0, percent: -2.5)
      expect(gl).to be_negative
    end

    it "returns false for positive absolute" do
      gl = GainLoss.new(absolute: 100.0, percent: 5.0)
      expect(gl).not_to be_negative
    end
  end

  describe "#zero?" do
    it "returns true when absolute is zero" do
      gl = GainLoss.new(absolute: 0.0, percent: 0.0)
      expect(gl).to be_zero
    end
  end

  describe "#to_s" do
    it "formats positive gain with plus sign" do
      gl = GainLoss.new(absolute: 150.555, percent: 3.456)
      expect(gl.to_s).to eq("+150.56 (+3.46%)")
    end

    it "formats negative gain without plus sign" do
      gl = GainLoss.new(absolute: -50.0, percent: -2.5)
      expect(gl.to_s).to eq("-50.0 (-2.5%)")
    end
  end
end
