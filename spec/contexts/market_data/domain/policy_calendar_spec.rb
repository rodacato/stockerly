require "rails_helper"

RSpec.describe MarketData::Domain::PolicyCalendar do
  describe ".upcoming" do
    it "returns the next events in date order, skipping the past" do
      events = described_class.upcoming(limit: 2, today: Date.new(2026, 9, 20))

      expect(events.map(&:date)).to eq([ Date.new(2026, 9, 24), Date.new(2026, 10, 28) ])
    end

    it "reads the Fed's own tentative flag rather than assuming" do
      fomc = described_class.upcoming(limit: 5, today: Date.new(2026, 1, 1))
                            .find { |event| event.source == "Fed" }
      banxico = described_class.upcoming(limit: 5, today: Date.new(2026, 1, 1))
                               .find { |event| event.source == "Banxico" }

      expect(fomc.tentative).to be true
      expect(banxico.tentative).to be false
    end
  end

  describe ".exhausted?" do
    it "is false while the file still has dates ahead" do
      expect(described_class.exhausted?(today: Date.new(2026, 12, 1))).to be false
    end

    # D33: the state that decides whether the block says something or renders
    # nothing on the one surface that works without a credential.
    it "is true once every date in the file is behind us" do
      expect(described_class.exhausted?(today: Date.new(2027, 1, 1))).to be true
    end
  end

  it "declares the year it claims to cover" do
    expect(described_class.horizon).to eq(2026)
  end

  it "names the sources a reader can go check" do
    expect(described_class.source_urls.keys).to contain_exactly("banxico", "fed")
  end
end
