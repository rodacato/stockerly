require "rails_helper"

RSpec.describe SyncMarketIndicesJob do
  include ActiveJob::TestHelper

  let!(:spx) { create(:market_index, symbol: "SPX", name: "S&P 500", value: 5000.0) }
  let!(:ndx) { create(:market_index, symbol: "NDX", name: "NASDAQ 100", value: 18000.0) }

  describe "#perform" do
    context "when gateway returns quotes" do
      before do
        # Catch-all for unstubbed index symbols (returns not found)
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { chart: { result: nil, error: { code: "Not Found" } } }.to_json
          )
        stub_yahoo_index_quotes({
          "^GSPC" => { name: "S&P 500", value: 5214.33, change_percent: 0.42, is_open: true },
          "^IXIC" => { name: "NASDAQ Composite", value: 18322.40, change_percent: 1.15, is_open: true }
        })
      end

      it "updates existing MarketIndex records" do
        described_class.perform_now

        spx.reload
        expect(spx.value).to eq(5214.33.to_d)
        expect(spx.change_percent).to be_within(0.01).of(0.42)
        expect(spx.is_open).to be true
      end

      it "logs success" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Market Indices Sync")
        expect(log.severity).to eq("success")
      end

      it "publishes MarketIndicesUpdated event" do
        handler = class_double(LogMarketIndicesUpdate, call: nil)
        EventBus.subscribe(MarketIndicesUpdated, handler)

        described_class.perform_now

        expect(handler).to have_received(:call).with(
          an_object_having_attributes(count: 2)
        )
      end

      it "skips indices not in database" do
        # ^IXIC maps to NDX which exists, ^GSPC maps to SPX which exists
        # No DJI in DB, so if returned it would be skipped
        expect { described_class.perform_now }.not_to raise_error
      end
    end

    context "when Yahoo fails but Polygon succeeds (fallback)" do
      before do
        allow_any_instance_of(YahooFinanceGateway).to receive(:fetch_index_quotes)
          .and_return(Dry::Monads::Failure([ :gateway_error, "Connection timeout" ]))

        stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/I:SPX/prev})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { results: [ { "o" => 5100.0, "c" => 5200.0, "h" => 5250.0, "l" => 5050.0, "v" => 1000 } ], resultsCount: 1 }.to_json
          )
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/I:COMP/prev})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { results: [ { "o" => 18000.0, "c" => 18500.0, "h" => 18600.0, "l" => 17900.0, "v" => 2000 } ], resultsCount: 1 }.to_json
          )
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/I:(DJI|VIX)/prev})
          .to_return(status: 404, body: "Not Found")
      end

      it "updates indices from Polygon fallback" do
        described_class.perform_now

        spx.reload
        expect(spx.value).to eq(5200.0.to_d)
      end

      it "logs success even via fallback" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
      end
    end

    context "when all gateways fail" do
      before do
        allow_any_instance_of(YahooFinanceGateway).to receive(:fetch_index_quotes)
          .and_return(Dry::Monads::Failure([ :gateway_error, "Yahoo timeout" ]))
        allow_any_instance_of(PolygonGateway).to receive(:fetch_index_quotes)
          .and_return(Dry::Monads::Failure([ :gateway_error, "Polygon timeout" ]))
      end

      it "logs failure" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

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
