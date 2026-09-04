require "rails_helper"

RSpec.describe MarketData::Discover::VisitLog do
  # The test env runs :null_store and this is the screen's only storage.
  before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

  it "remembers when the screen was last opened" do
    moment = Time.current

    described_class.record(now: moment)

    expect(described_class.last_seen).to be_within(1.second).of(moment)
  end

  # The criterion is "opened in at least 4 of 8 weeks", which a single
  # timestamp cannot answer — it says when, never how often.
  describe "counting the weeks it was opened in" do
    # Anchored mid-week on purpose: counting back in hours from Time.current
    # crosses into the previous ISO week whenever the suite runs in the small
    # hours of a Monday, which made this fail for two hours every week.
    it "counts one week however many times it was opened that week" do
      midweek = Time.zone.parse("2026-01-14 12:00")

      3.times { |i| described_class.record(now: midweek - i.hours) }

      expect(described_class.weeks_seen(now: midweek)).to eq(1)
    end

    it "counts distinct weeks inside the window" do
      [ 0, 1, 3 ].each { |back| described_class.record(now: Time.current - back.weeks) }

      expect(described_class.weeks_seen).to eq(3)
    end

    it "ignores weeks that fell out of the window" do
      described_class.record(now: 20.weeks.ago)
      described_class.record(now: Time.current)

      expect(described_class.weeks_seen).to eq(1)
    end

    it "is zero on an instance where nobody has opened it" do
      expect(described_class.weeks_seen).to eq(0)
    end

    # A run at the turn of the year must not fold two weeks into one key.
    it "keeps weeks either side of a year boundary apart" do
      described_class.record(now: Time.zone.parse("2026-12-30"))
      described_class.record(now: Time.zone.parse("2027-01-05"))

      expect(described_class.weeks_seen(now: Time.zone.parse("2027-01-05"))).to eq(2)
    end
  end
end
