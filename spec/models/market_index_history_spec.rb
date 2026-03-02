require "rails_helper"

RSpec.describe MarketIndexHistory, type: :model do
  subject(:history) { build(:market_index_history) }

  describe "associations" do
    it "belongs to a market_index" do
      expect(history.market_index).to be_a(MarketIndex)
    end
  end

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires date" do
      history.date = nil
      expect(history).not_to be_valid
    end

    it "requires close_value" do
      history.close_value = nil
      expect(history).not_to be_valid
    end

    it "requires close_value to be positive" do
      history.close_value = -1
      expect(history).not_to be_valid
    end

    it "enforces uniqueness of date per market_index" do
      existing = create(:market_index_history)
      duplicate = build(:market_index_history,
        market_index: existing.market_index,
        date: existing.date)
      expect(duplicate).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:index) { create(:market_index) }
    let!(:old) { create(:market_index_history, market_index: index, date: 10.days.ago.to_date, close_value: 4_800) }
    let!(:mid) { create(:market_index_history, market_index: index, date: 5.days.ago.to_date, close_value: 4_900) }
    let!(:recent) { create(:market_index_history, market_index: index, date: 1.day.ago.to_date, close_value: 5_000) }

    describe ".recent" do
      it "returns records ordered by date descending" do
        expect(described_class.recent.pluck(:id)).to eq([ recent.id, mid.id, old.id ])
      end
    end

    describe ".for_period" do
      it "returns records within the given date range ordered by date" do
        results = described_class.for_period(6.days.ago.to_date, Date.current)
        expect(results.pluck(:id)).to eq([ mid.id, recent.id ])
      end
    end
  end
end
