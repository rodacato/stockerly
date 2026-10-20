require "rails_helper"

RSpec.describe AppOpen, type: :model do
  let(:day) { Date.new(2026, 10, 20) }

  describe ".record" do
    it "creates the row on the first open and counts the next ones on the same row" do
      3.times { described_class.record(path: "/dashboard", day:) }

      expect(described_class.where(path: "/dashboard", day:).pluck(:count)).to eq([ 3 ])
    end

    it "keeps days and paths apart" do
      described_class.record(path: "/dashboard", day:)
      described_class.record(path: "/dashboard", day: day + 1)
      described_class.record(path: "/hoy", day:)

      expect(described_class.count).to eq(3)
    end
  end

  describe ".per_day" do
    it "returns one entry per day, oldest first, with zero for days not opened" do
      2.times { described_class.record(path: "/dashboard", day:) }
      described_class.record(path: "/dashboard", day: day - 2)
      described_class.record(path: "/hoy", day:)

      series = described_class.per_day(path: "/dashboard", days: 3, today: day)

      expect(series).to eq([ [ day - 2, 1 ], [ day - 1, 0 ], [ day, 2 ] ])
    end

    it "ignores days outside the window" do
      described_class.record(path: "/dashboard", day: day - 14)

      series = described_class.per_day(path: "/dashboard", days: 14, today: day)

      expect(series.sum(&:last)).to eq(0)
      expect(series.size).to eq(14)
    end
  end
end
