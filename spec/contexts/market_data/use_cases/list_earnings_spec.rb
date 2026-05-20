require "rails_helper"

RSpec.describe MarketData::UseCases::ListEarnings do
  let(:user) { create(:user) }

  let(:walmex)  { create(:asset, :stock, symbol: "WALMEX.MX",  exchange: "BMV",    currency: "MXN") }
  let(:apple)   { create(:asset, :stock, symbol: "AAPL",       exchange: "NASDAQ", currency: "USD") }
  let(:nvda)    { create(:asset, :stock, symbol: "NVDA",       exchange: "NASDAQ", currency: "USD") }
  let(:ko)      { create(:asset, :stock, symbol: "KO",         exchange: "NYSE",   currency: "USD") }

  let!(:walmex_event) { create(:earnings_event, asset: walmex, report_date: 2.days.from_now.to_date) }
  let!(:apple_event)  { create(:earnings_event, asset: apple,  report_date: 4.days.from_now.to_date) }
  let!(:nvda_event)   { create(:earnings_event, asset: nvda,   report_date: 5.days.from_now.to_date) }
  let!(:recent_event) { create(:earnings_event, asset: ko,     report_date: 3.days.ago.to_date, actual_eps: 0.65, estimated_eps: 0.62) }

  before do
    create(:watchlist_item, user: user, asset: walmex)
  end

  describe ".call" do
    it "returns upcoming events grouped by date + recent + counts" do
      data = described_class.call(user: user)

      expect(data[:periodo]).to eq("semana")
      expect(data[:mercado]).to eq("todos")
      expect(data[:watchlist_only]).to be false

      group_dates = data[:upcoming].map(&:first)
      expect(group_dates).to eq([ walmex_event.report_date, apple_event.report_date, nvda_event.report_date ])

      expect(data[:recent]).to contain_exactly(recent_event)
      expect(data[:counts][:upcoming]).to eq(3)
      expect(data[:counts][:recent]).to eq(1)
      expect(data[:counts][:watchlist]).to eq(1)
    end

    it "filters by mercado (BMV)" do
      data = described_class.call(user: user, mercado: "BMV")
      events_in_groups = data[:upcoming].flat_map(&:last)
      expect(events_in_groups).to contain_exactly(walmex_event)
      expect(data[:counts][:upcoming]).to eq(1)
    end

    it "filters by mercado (NASDAQ)" do
      data = described_class.call(user: user, mercado: "NASDAQ")
      events_in_groups = data[:upcoming].flat_map(&:last)
      expect(events_in_groups).to contain_exactly(apple_event, nvda_event)
    end

    it "ignores unknown mercado values (acts as 'todos')" do
      data = described_class.call(user: user, mercado: "XYZ")
      expect(data[:counts][:upcoming]).to eq(3)
    end

    it "filters by watchlist_only" do
      data = described_class.call(user: user, watchlist_only: true)
      events_in_groups = data[:upcoming].flat_map(&:last)
      expect(events_in_groups).to contain_exactly(walmex_event)
    end

    it "extends the lookahead window when periodo=mes" do
      create(:earnings_event, asset: apple, report_date: 20.days.from_now.to_date)
      data = described_class.call(user: user, periodo: "mes")
      expect(data[:counts][:upcoming]).to be >= 4
    end

    it "falls back to semana when periodo is invalid" do
      data = described_class.call(user: user, periodo: "nope")
      expect(data[:periodo]).to eq("semana")
    end

    it "watchlist count reflects the active mercado filter" do
      create(:watchlist_item, user: user, asset: apple)
      data = described_class.call(user: user, mercado: "BMV")
      expect(data[:counts][:watchlist]).to eq(1)
    end

    it "computes watchlist count from the already-loaded upcoming array (no extra query)" do
      # If a regression re-introduces a per-call EarningsEvent.where(...).count
      # for the watchlist counter, query count climbs past the cap.
      expect { described_class.call(user: user) }.to make_queries(at_most: 8)
    end
  end
end
