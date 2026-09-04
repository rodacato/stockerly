require "rails_helper"

RSpec.describe MarketData::Queries::MarketCalendar do
  let(:date) { Date.new(2026, 9, 16) }

  describe ".holiday_on" do
    it "returns the holiday so the caller can name it" do
      MarketHoliday.create!(market: :BMV, date: date, name: "Independencia")

      expect(described_class.holiday_on(market: :BMV, date: date).name).to eq("Independencia")
    end

    it "returns nil when the market trades that day" do
      expect(described_class.holiday_on(market: :BMV, date: date)).to be_nil
    end

    it "does not answer for a market that did not close" do
      MarketHoliday.create!(market: :Banxico, date: date, name: "Independencia")

      expect(described_class.holiday_on(market: :BMV, date: date)).to be_nil
    end
  end

  describe ".holiday?" do
    it "is true only for the market that closed" do
      MarketHoliday.create!(market: :Banxico, date: date, name: "Independencia")

      expect(described_class.holiday?(market: :Banxico, date: date)).to be(true)
      expect(described_class.holiday?(market: :BMV, date: date)).to be(false)
    end
  end

  describe ".dates_in_year" do
    it "returns one market's closures for one year" do
      MarketHoliday.create!(market: :NYSE, date: Date.new(2026, 11, 26), name: "Thanksgiving")
      MarketHoliday.create!(market: :NYSE, date: Date.new(2027, 11, 25), name: "Thanksgiving")
      MarketHoliday.create!(market: :BMV,  date: Date.new(2026, 12, 25), name: "Navidad")

      expect(described_class.dates_in_year(market: :NYSE, year: 2026)).to eq([ Date.new(2026, 11, 26) ])
    end

    # Empty is how a caller learns the calendar does not reach that year, which
    # is why the read returns the dates rather than a boolean.
    it "is empty for a year the calendar does not reach" do
      MarketHoliday.create!(market: :NYSE, date: Date.new(2026, 11, 26), name: "Thanksgiving")

      expect(described_class.dates_in_year(market: :NYSE, year: 2028)).to be_empty
    end
  end

  describe ".covered_through" do
    it "reports the last date the calendar reaches for a market" do
      MarketHoliday.create!(market: :NYSE, date: Date.new(2026, 11, 26), name: "Thanksgiving")
      MarketHoliday.create!(market: :NYSE, date: Date.new(2027, 12, 24), name: "Christmas")

      expect(described_class.covered_through(market: :NYSE)).to eq(Date.new(2027, 12, 24))
    end

    it "is nil when the market has no calendar at all" do
      expect(described_class.covered_through(market: :NYSE)).to be_nil
    end
  end
end
