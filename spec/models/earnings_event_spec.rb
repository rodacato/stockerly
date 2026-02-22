require "rails_helper"

RSpec.describe EarningsEvent, type: :model do
  subject(:event) { build(:earnings_event) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires report_date" do
      event.report_date = nil
      expect(event).not_to be_valid
    end

    it "requires timing" do
      event.timing = nil
      expect(event).not_to be_valid
    end

    it "requires unique report_date per asset" do
      asset = create(:asset)
      create(:earnings_event, asset: asset, report_date: "2026-03-15")
      dup = build(:earnings_event, asset: asset, report_date: "2026-03-15")
      expect(dup).not_to be_valid
    end
  end

  describe "enums" do
    it "defines timing enum" do
      expect(EarningsEvent.timings).to eq(
        "before_market_open" => 0, "after_market_close" => 1
      )
    end
  end

  describe "scopes" do
    let(:asset) { create(:asset) }

    it ".for_month returns events for a given month" do
      march = create(:earnings_event, asset: asset, report_date: "2026-03-15")
      april = create(:earnings_event, asset: create(:asset), report_date: "2026-04-10")
      expect(EarningsEvent.for_month(Date.new(2026, 3, 1))).to contain_exactly(march)
    end

    it ".upcoming returns future events ordered by date" do
      past = create(:earnings_event, asset: asset, report_date: 1.month.ago)
      future = create(:earnings_event, asset: create(:asset), report_date: 1.month.from_now)
      expect(EarningsEvent.upcoming).to contain_exactly(future)
    end
  end
end
