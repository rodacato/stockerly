require "rails_helper"

RSpec.describe SyncMarketIndicesJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let!(:spx) { create(:market_index, symbol: "SPX", name: "S&P 500", value: 5000.0) }
  let!(:ndx) { create(:market_index, symbol: "NDX", name: "NASDAQ 100", value: 18000.0) }

  # Index levels come through the yfinance bridge, which is a subprocess and so
  # is stubbed at the runner rather than with WebMock.
  def stub_bridge(quotes)
    allow(PythonRunner).to receive(:call) do |_script, _command, symbol|
      quote = quotes[symbol]
      quote ? Dry::Monads::Success(quote) : Dry::Monads::Failure([ :not_found, "no data for #{symbol}" ])
    end
  end

  # Every example below assumes a session is running. The job no longer goes
  # out to the provider when both markets are closed, so without anchoring the
  # clock these pass or fail depending on the hour the suite runs.
  describe "#perform" do
    around { |example| travel_to(Time.zone.parse("2026-08-26 12:00:00 EST")) { example.run } }

    context "when the bridge returns quotes" do
      before do
        stub_bridge({
          "^GSPC" => { "price" => 5214.33, "change_percent" => 0.42, "volume" => 1_000 },
          "^IXIC" => { "price" => 18_322.40, "change_percent" => 1.15, "volume" => 2_000 }
        })
      end

      # The change percentage assertion is the guard for #479: the four
      # asset-quote gateways stopped returning `change_percent` because nothing
      # read it, and `fetch_index_quotes` builds on `fetch_price`, so this is
      # the path that must not go with them.
      it "updates existing MarketIndex records" do
        described_class.perform_now

        spx.reload
        expect(spx.value).to eq(5214.33.to_d)
        expect(spx.change_percent).to be_within(0.01).of(0.42)
      end

      it "logs success" do
        expect { described_class.perform_now }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Market Indices Sync")
        expect(log.severity).to eq("success")
      end

      it "publishes MarketIndicesUpdated event" do
        handler = class_double("SomeHandler", call: nil)
        EventBus.subscribe(MarketData::Events::MarketIndicesUpdated, handler)

        described_class.perform_now

        expect(handler).to have_received(:call).with(an_object_having_attributes(count: 2))
      end

      it "skips indices the instance does not track" do
        expect { described_class.perform_now }.not_to raise_error
      end
    end

    # The IPC is the reason this path exists: DataBursatil's index feed has been
    # frozen since 2026-06-26 and nothing else serves it.
    context "when the bridge returns the IPC" do
      let!(:ipc) { create(:market_index, symbol: "IPC", name: "S&P/BMV IPC", value: 60_000.0) }

      before { stub_bridge({ "^MXX" => { "price" => 66_440.9, "change_percent" => 0.22, "volume" => 31_379_135 } }) }

      it "updates it" do
        described_class.perform_now

        expect(ipc.reload.value).to eq(66_440.9.to_d)
      end
    end

    # #553 read the absence of "vix" from recurring.yml as "nothing refreshes
    # the VIX". The schedule names jobs, not symbols: this job carries ^VIX in
    # INDEX_SYMBOL_MAP and runs every ten minutes, and MarketIndex.vix is the
    # row it writes.
    context "when the bridge returns the VIX" do
      let!(:vix) { create(:market_index, symbol: "VIX", name: "CBOE Volatility", value: 14.0) }

      before { stub_bridge({ "^VIX" => { "price" => 18.72, "change_percent" => 3.10, "volume" => 0 } }) }

      it "refreshes the row MarketIndex.vix reads" do
        described_class.perform_now

        expect(MarketIndex.vix.value).to eq(18.72.to_d)
      end
    end

    context "when the bridge fails for every symbol" do
      before { stub_bridge({}) }

      it "logs failure" do
        expect { described_class.perform_now }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Market Indices Sync")
        expect(log.severity).to eq("error")
      end

      it "does not update indices" do
        described_class.perform_now

        expect(spx.reload.value).to eq(5000.0.to_d)
      end
    end
  end

  # 864 provider calls a day, six per run every ten minutes, and overnight
  # every one of them asks about a market that closed hours ago.
  describe "outside market hours" do
    around { |example| travel_to(Time.zone.parse("2026-08-26 22:00:00 EST")) { example.run } }

    it "does not reach the provider at all" do
      expect(PythonRunner).not_to receive(:call)

      described_class.perform_now
    end

    it "writes no log line, because a skipped run is not news every ten minutes" do
      expect { described_class.perform_now }.not_to change(SystemLog, :count)
    end

    # Skipping without this would leave every index reading "open" all night,
    # which is worse than the calls it saves.
    it "closes the indices it left open" do
      spx.update!(is_open: true)

      described_class.perform_now

      expect(spx.reload.is_open).to be(false)
    end
  end
end
