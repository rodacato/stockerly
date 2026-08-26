require "rails_helper"

RSpec.describe SyncMarketIndicesJob do
  include ActiveJob::TestHelper

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

  describe "#perform" do
    context "when the bridge returns quotes" do
      before do
        stub_bridge({
          "^GSPC" => { "price" => 5214.33, "change_percent" => 0.42, "volume" => 1_000 },
          "^IXIC" => { "price" => 18_322.40, "change_percent" => 1.15, "volume" => 2_000 }
        })
      end

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
        handler = class_double(MarketData::Handlers::LogMarketIndicesUpdate, call: nil)
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
end
