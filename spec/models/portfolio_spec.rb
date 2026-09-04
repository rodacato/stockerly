require "rails_helper"

RSpec.describe Portfolio, type: :model do
  subject(:portfolio) { build(:portfolio) }

  describe "validations" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    let(:user)      { create(:user) }
    let(:portfolio) { create(:portfolio, user: user) }

    it "belongs to user" do
      expect(portfolio.user).to eq(user)
    end

    it "destroys positions on destroy" do
      asset = create(:asset)
      create(:position, portfolio: portfolio, asset: asset)
      expect { portfolio.destroy }.to change(Position, :count).by(-1)
    end

    it "destroys trades on destroy" do
      asset = create(:asset)
      create(:trade, portfolio: portfolio, asset: asset)
      expect { portfolio.destroy }.to change(Trade, :count).by(-1)
    end
  end

  describe "#open_positions / #closed_positions" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset) }
    let!(:open_pos)   { create(:position, portfolio: portfolio, asset: asset, status: :open) }
    let!(:closed_pos) { create(:position, portfolio: portfolio, asset: create(:asset), status: :closed, closed_at: Time.current) }

    it "#open_positions returns only open" do
      expect(portfolio.open_positions).to contain_exactly(open_pos)
    end

    it "#closed_positions returns only closed" do
      expect(portfolio.closed_positions).to contain_exactly(closed_pos)
    end
  end

  describe "#total_value" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset, current_price: 100.0) }

    it "sums open position market values" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      expect(portfolio.total_value).to eq(1_000.0)
    end

    it "is zero with no positions — there is no cash concept" do
      expect(portfolio.total_value).to eq(0)
    end
  end

  describe "#total_unrealized_gain" do
    let(:portfolio) { create(:portfolio) }
    let(:asset)     { create(:asset, current_price: 150.0) }

    it "calculates unrealized gain from open positions" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0, status: :open)
      expect(portfolio.total_unrealized_gain).to eq(500.0)
    end
  end

  describe "#yesterday_snapshot" do
    let(:portfolio) { create(:portfolio) }

    it "returns nil when no snapshot exists" do
      expect(portfolio.yesterday_snapshot).to be_nil
    end

    it "returns yesterday's snapshot" do
      snap = create(:portfolio_snapshot, portfolio: portfolio, date: Date.yesterday)
      expect(portfolio.yesterday_snapshot).to eq(snap)
    end
  end

  # #537 / ADR-0023 amendment. Banxico's FIX has legitimate holes, so a figure
  # dated inside one settles against the nearest prior rate. Past the window it
  # absents itself rather than borrow a rate from another month.
  describe "#convert with an at_date" do
    let(:portfolio) { create(:portfolio) }
    let(:asked_on)  { Date.new(2026, 4, 5) }

    def record_fix(date, rate)
      FxRateHistory.record(base: "USD", quote: "MXN", date: date, rate: rate, source: "banxico")
    end

    it "settles against the nearest prior rate inside the window" do
      record_fix(asked_on - Portfolio::MAX_RATE_STALENESS_DAYS, 17.05)

      expect(portfolio.convert(100, from: "USD", to: "MXN", at_date: asked_on)).to eq(1_705.0)
    end

    it "absents the figure when the nearest prior rate is older than the window" do
      record_fix(asked_on - Portfolio::MAX_RATE_STALENESS_DAYS - 1, 17.05)

      expect { portfolio.convert(100, from: "USD", to: "MXN", at_date: asked_on) }
        .to raise_error(Trading::Domain::MissingFxRate)
    end

    # The defect itself: `fx_rates` holds one undated row per pair, so falling
    # back to it valued a March figure at today's rate and said nothing.
    it "never reaches for today's rate to value a past date" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 21.00)

      expect { portfolio.convert(100, from: "USD", to: "MXN", at_date: asked_on) }
        .to raise_error(Trading::Domain::MissingFxRate)
      expect(portfolio.convert(100, from: "USD", to: "MXN")).to eq(2_100.0)
    end

    # An absent rate is now a real outcome, so it has to be cached like any
    # other — a year-long chart would otherwise ask the store once per point.
    it "asks the store once per pair and date, absent or not" do
      allow(FxRateHistory).to receive(:quote_on).and_call_original

      2.times do
        portfolio.convert(100, from: "USD", to: "MXN", at_date: asked_on)
      rescue Trading::Domain::MissingFxRate
        nil
      end

      expect(FxRateHistory).to have_received(:quote_on).once
    end
  end
end
