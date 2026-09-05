require "rails_helper"

RSpec.describe Trading::Domain::PositionReturns do
  let(:user) { create(:user, preferred_currency: "USD") }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset) { create(:asset, symbol: "NVDA", currency: "USD") }

  def close(date, price)
    create(:asset_price_history, asset: asset, date: date, close: price, open: price, high: price, low: price)
  end

  def buy(shares, price, on:)
    create(:trade, portfolio: portfolio, asset: asset, side: :buy,
                   shares: shares, price_per_share: price, executed_at: on)
  end

  def windows_for
    described_class.new(portfolio, asset, currency: "USD").windows.index_by(&:key)
  end

  describe "a position held through the whole window" do
    before do
      buy(10, 100, on: 400.days.ago)
      400.downto(0) { |d| close(d.days.ago.to_date, 100 + ((400 - d) * 0.1)) }
    end

    it "reports what the window made in money" do
      # One day of drift at 0.10 a day, ten shares. Asserted on 1D because its
      # boundary is exact; a month's is whatever the calendar says it is.
      expect(windows_for["1D"].amount).to be_within(0.01).of(10 * 0.1)
    end

    it "states the move as a percentage of what was in at the start" do
      w = windows_for["1A"]

      expect(w.percent).to be_within(0.5).of(w.amount / (10 * (100 + (35 * 0.1))) * 100)
    end

    it "offers every window, because the position outlives all of them" do
      expect(windows_for.keys).to match_array(%w[1D 1S 1M 3M 1A])
    end
  end

  describe "a window that opens before the position did" do
    before do
      buy(10, 100, on: 3.days.ago)
      10.downto(0) { |d| close(d.days.ago.to_date, 100 + d) }
    end

    it "is absent rather than zero — not owning it is not the same as not moving" do
      expect(windows_for.keys).to eq(%w[1D])
      expect(windows_for["1S"]).to be_nil
    end
  end

  describe "money added inside the window" do
    before do
      buy(10, 100, on: 60.days.ago)
      60.downto(0) { |d| close(d.days.ago.to_date, 100) }
      buy(10, 100, on: 5.days.ago)
    end

    # The price never moved, so the position earned nothing. A plain
    # start-to-end diff would call the second purchase a 100% gain — D12's
    # falsehood, at position scope.
    it "does not count a purchase as a return" do
      expect(windows_for["1M"].amount).to be_within(0.01).of(0)
      expect(windows_for["1M"].percent).to be_within(0.01).of(0)
    end
  end

  describe "a sale inside the window" do
    before do
      buy(20, 100, on: 60.days.ago)
      60.downto(0) { |d| close(d.days.ago.to_date, 100) }
      create(:trade, portfolio: portfolio, asset: asset, side: :sell,
                     shares: 10, price_per_share: 100, executed_at: 5.days.ago)
    end

    it "does not read taking money out as a loss" do
      expect(windows_for["1M"].amount).to be_within(0.01).of(0)
    end
  end

  describe "an asset with no price history at all" do
    before { buy(10, 100, on: 30.days.ago) }

    it "reports nothing rather than guessing" do
      expect(windows_for).to be_empty
    end
  end

  describe "the windows offered" do
    it "does not include Total, which Tu posición already is" do
      expect(described_class::WINDOWS.keys).not_to include("Total")
    end
  end
end
