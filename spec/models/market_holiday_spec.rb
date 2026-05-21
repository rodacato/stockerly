require "rails_helper"

RSpec.describe MarketHoliday, type: :model do
  describe "validations" do
    it "requires date + name + market" do
      h = MarketHoliday.new
      expect(h).not_to be_valid
      expect(h.errors).to be_added(:date, :blank)
      expect(h.errors).to be_added(:name, :blank)
    end

    it "rejects a duplicate date+market pair" do
      MarketHoliday.create!(market: :BMV, date: Date.new(2026, 1, 1), name: "Año Nuevo")
      dup = MarketHoliday.new(market: :BMV, date: Date.new(2026, 1, 1), name: "Otra cosa")
      expect(dup).not_to be_valid
    end

    it "allows the same date across markets" do
      MarketHoliday.create!(market: :BMV,     date: Date.new(2026, 1, 1), name: "Año Nuevo")
      cross = MarketHoliday.new(market: :Banxico, date: Date.new(2026, 1, 1), name: "Año Nuevo Banxico")
      expect(cross).to be_valid
    end
  end

  describe ".holiday?" do
    it "returns true when a record exists for the market+date" do
      MarketHoliday.create!(market: :BMV, date: Date.new(2026, 9, 16), name: "Independencia")
      expect(MarketHoliday.holiday?(market: :BMV, date: Date.new(2026, 9, 16))).to be true
    end

    it "returns false when only the OTHER market has the date" do
      MarketHoliday.create!(market: :BMV, date: Date.new(2026, 12, 12), name: "Guadalupe")
      expect(MarketHoliday.holiday?(market: :Banxico, date: Date.new(2026, 12, 12))).to be false
    end
  end

  describe ".weekday?" do
    it "returns true for Mon-Fri" do
      expect(MarketHoliday.weekday?(Date.new(2026, 5, 18))).to be true # Monday
      expect(MarketHoliday.weekday?(Date.new(2026, 5, 22))).to be true # Friday
    end

    it "returns false for Sat-Sun" do
      expect(MarketHoliday.weekday?(Date.new(2026, 5, 16))).to be false # Saturday
      expect(MarketHoliday.weekday?(Date.new(2026, 5, 17))).to be false # Sunday
    end
  end

  describe ".next_business_day" do
    it "returns `from` itself when it is a non-holiday weekday" do
      expect(MarketHoliday.next_business_day(market: :BMV, from: Date.new(2026, 5, 19))).to eq(Date.new(2026, 5, 19))
    end

    it "skips weekends" do
      # Saturday 2026-05-16 → Monday 2026-05-18
      expect(MarketHoliday.next_business_day(market: :BMV, from: Date.new(2026, 5, 16))).to eq(Date.new(2026, 5, 18))
    end

    it "skips a holiday landing on a weekday" do
      MarketHoliday.create!(market: :BMV, date: Date.new(2026, 5, 18), name: "Festivo test")
      expect(MarketHoliday.next_business_day(market: :BMV, from: Date.new(2026, 5, 18))).to eq(Date.new(2026, 5, 19))
    end
  end

  describe ".upcoming" do
    it "returns only holidays today-or-future in date order" do
      past   = MarketHoliday.create!(market: :BMV, date: 5.days.ago.to_date,     name: "Past")
      today  = MarketHoliday.create!(market: :BMV, date: Date.current,           name: "Today")
      future = MarketHoliday.create!(market: :BMV, date: 10.days.from_now.to_date, name: "Future")

      expect(MarketHoliday.upcoming).to eq([ today, future ])
    end
  end
end
