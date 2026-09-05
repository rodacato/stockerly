require "rails_helper"

RSpec.describe Trading::Domain::SplitAdjuster do
  let(:asset) { create(:asset, :stock) }
  let(:portfolio) { create(:portfolio) }
  let(:ex_date) { 1.week.ago.to_date }

  def adjuster(ratio_from: 1, ratio_to: 4, on: ex_date)
    described_class.new(asset_id: asset.id, ex_date: on, ratio_from: ratio_from, ratio_to: ratio_to)
  end

  # A healthy position agrees with its trades, so the fixtures state both.
  def position_for(shares:, avg_cost:, opened_at: 2.months.ago, status: :open)
    create(:position, portfolio: portfolio, asset: asset, shares: shares,
                      avg_cost: avg_cost, status: status, opened_at: opened_at)
  end

  def buy(position, shares:, price:, on:)
    create(:trade, portfolio: portfolio, asset: asset, position: position,
                   side: :buy, shares: shares, price_per_share: price, executed_at: on)
  end

  describe "a split the position was held through" do
    let!(:position) { position_for(shares: 100, avg_cost: 200.0) }
    let!(:trade) { buy(position, shares: 100, price: 200.0, on: 2.months.ago) }

    it "rewrites the trade into post-split terms" do
      adjuster.adjust!

      trade.reload
      expect(trade.shares).to eq(400)
      expect(trade.price_per_share).to eq(50.0)
    end

    it "re-derives the position from the rewritten trade" do
      adjuster.adjust!

      position.reload
      expect(position.shares).to eq(400)
      expect(position.avg_cost).to eq(50.0)
    end

    it "leaves the cost basis untouched" do
      expect { adjuster.adjust! }
        .not_to(change { position.reload.shares * position.avg_cost })
    end
  end

  # Back-applying a historical split to shares bought after it inflates the
  # position without touching its trades, and the portfolio with it.
  describe "a split that happened before the position existed" do
    let!(:position) { position_for(shares: 10, avg_cost: 300.0, opened_at: 2.days.ago) }
    let!(:trade) { buy(position, shares: 10, price: 300.0, on: 2.days.ago) }

    it "leaves the position alone" do
      adjuster.adjust!

      position.reload
      expect(position.shares).to eq(10)
      expect(position.avg_cost).to eq(300.0)
    end

    it "leaves the post-split trade alone" do
      adjuster.adjust!

      trade.reload
      expect(trade.shares).to eq(10)
      expect(trade.price_per_share).to eq(300.0)
    end

    it "still records that the split landed" do
      expect { adjuster.adjust! }
        .to change { SplitAdjustment.where(asset_id: asset.id).count }.from(0).to(1)
    end
  end

  describe "a position holding shares from both sides of the split" do
    let!(:position) { position_for(shares: 20, avg_cost: 200.0) }

    before do
      buy(position, shares: 10, price: 200.0, on: 2.months.ago)
      buy(position, shares: 10, price: 50.0, on: 2.days.ago)
    end

    it "scales only the shares bought before the ex-date" do
      adjuster.adjust!

      expect(position.reload.shares).to eq(50)
    end
  end

  describe "splits that land together" do
    let!(:position) { position_for(shares: 100, avg_cost: 200.0) }

    before { buy(position, shares: 100, price: 200.0, on: 2.months.ago) }

    it "composes rather than overwriting" do
      adjuster(ratio_to: 4).adjust!
      adjuster(ratio_to: 10, on: ex_date - 1.day).adjust!

      expect(position.reload.shares).to eq(4000)
    end
  end

  describe "shares entered without a trade history" do
    it "scales what was already held before the ex-date" do
      position = position_for(shares: 100, avg_cost: 200.0, opened_at: 2.months.ago)

      adjuster.adjust!

      position.reload
      expect(position.shares).to eq(400)
      expect(position.avg_cost).to eq(50.0)
    end

    it "leaves alone what was acquired after it" do
      position = position_for(shares: 100, avg_cost: 200.0, opened_at: 2.days.ago)

      adjuster.adjust!

      expect(position.reload.shares).to eq(100)
    end
  end

  describe "closed positions" do
    it "re-derives them without reopening or restamping them" do
      closed = position_for(shares: 0, avg_cost: 200.0, status: :closed)
      closed.update!(closed_at: 1.month.ago)
      buy(closed, shares: 100, price: 200.0, on: 2.months.ago)
      create(:trade, portfolio: portfolio, asset: asset, position: closed,
                     side: :sell, shares: 100, price_per_share: 220.0, executed_at: 6.weeks.ago)

      expect { adjuster.adjust! }.not_to(change { closed.reload.closed_at })

      expect(closed.status).to eq("closed")
      expect(closed.avg_cost).to eq(50.0)
    end
  end

  describe "applying twice" do
    let!(:position) { position_for(shares: 100, avg_cost: 200.0) }
    let!(:trade) { buy(position, shares: 100, price: 200.0, on: 2.months.ago) }

    it "leaves the same numbers as applying once" do
      adjuster.adjust!
      adjuster.adjust!

      position.reload
      expect(position.shares).to eq(400)
      expect(position.avg_cost).to eq(50.0)
    end

    it "does not touch trades on the second pass" do
      adjuster.adjust!
      adjuster.adjust!

      expect(trade.reload.shares).to eq(400)
      expect(trade.price_per_share).to eq(50.0)
    end
  end

  describe "when the adjustment fails partway" do
    let!(:position) { position_for(shares: 100, avg_cost: 200.0) }

    before { buy(position, shares: 100, price: 200.0, on: 2.months.ago) }

    it "rolls back the rewrites it had already made" do
      allow(Position).to receive(:where).and_raise(ActiveRecord::StatementInvalid, "boom")

      expect { adjuster.adjust! }.to raise_error(ActiveRecord::StatementInvalid)

      expect(position.reload.shares).to eq(100)
      expect(SplitAdjustment.count).to eq(0)
    end
  end

  describe "the ex-date as a job payload round-trips it" do
    let!(:position) { position_for(shares: 100, avg_cost: 200.0) }

    before { buy(position, shares: 100, price: 200.0, on: 2.months.ago) }

    it "accepts a string" do
      described_class.new(asset_id: asset.id, ex_date: ex_date.iso8601, ratio_from: 1, ratio_to: 4).adjust!

      expect(position.reload.shares).to eq(400)
    end
  end
end
