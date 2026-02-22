require "rails_helper"

RSpec.describe FxRate, type: :model do
  subject(:rate) { build(:fx_rate) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires base_currency" do
      rate.base_currency = nil
      expect(rate).not_to be_valid
    end

    it "requires quote_currency" do
      rate.quote_currency = nil
      expect(rate).not_to be_valid
    end

    it "requires rate" do
      rate.rate = nil
      expect(rate).not_to be_valid
    end

    it "requires rate greater than 0" do
      rate.rate = 0
      expect(rate).not_to be_valid
    end

    it "requires fetched_at" do
      rate.fetched_at = nil
      expect(rate).not_to be_valid
    end

    it "requires unique base/quote currency pair" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN")
      rate.base_currency = "USD"
      rate.quote_currency = "MXN"
      expect(rate).not_to be_valid
    end
  end

  describe ".convert" do
    before do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.25)
    end

    it "converts amount using the rate" do
      result = FxRate.convert(100, from: "USD", to: "MXN")
      expect(result).to eq(1_725.0)
    end

    it "returns the same amount when from equals to" do
      expect(FxRate.convert(100, from: "USD", to: "USD")).to eq(100)
    end

    it "returns nil when no rate exists" do
      expect(FxRate.convert(100, from: "USD", to: "JPY")).to be_nil
    end
  end

  describe ".last_refresh" do
    it "returns the most recent fetched_at" do
      create(:fx_rate, fetched_at: 2.hours.ago)
      recent = create(:fx_rate, fetched_at: 10.minutes.ago)
      expect(FxRate.last_refresh).to be_within(1.second).of(recent.fetched_at)
    end

    it "returns nil when no rates exist" do
      expect(FxRate.last_refresh).to be_nil
    end
  end
end
