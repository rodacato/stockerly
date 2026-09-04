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
end
