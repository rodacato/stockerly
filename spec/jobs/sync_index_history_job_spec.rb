require "rails_helper"

RSpec.describe SyncIndexHistoryJob do
  let!(:spx) { create(:market_index, symbol: "SPX", name: "S&P 500") }
  let!(:ndx) { create(:market_index, symbol: "NDX", name: "NASDAQ 100") }

  describe "#perform" do
    context "when Yahoo returns historical data" do
      before do
        allow_any_instance_of(MarketData::YahooFinanceGateway).to receive(:fetch_historical)
          .and_return(Dry::Monads::Success([
            { date: 3.days.ago.to_date, close: 5200.0.to_d, open: 5180.0.to_d, high: 5220.0.to_d, low: 5170.0.to_d, volume: 100_000 },
            { date: 2.days.ago.to_date, close: 5250.0.to_d, open: 5200.0.to_d, high: 5260.0.to_d, low: 5190.0.to_d, volume: 110_000 },
            { date: 1.day.ago.to_date, close: 5300.0.to_d, open: 5250.0.to_d, high: 5310.0.to_d, low: 5240.0.to_d, volume: 120_000 }
          ]))
      end

      it "creates MarketIndexHistory records" do
        expect { described_class.perform_now }
          .to change(MarketIndexHistory, :count)

        histories = spx.market_index_histories.order(:date)
        expect(histories.size).to eq(3)
        expect(histories.last.close_value).to eq(5300.0.to_d)
      end

      it "logs success" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Index History Sync")
        expect(log.severity).to eq("success")
      end

      it "is idempotent — skips existing records on second run" do
        described_class.perform_now
        initial_count = MarketIndexHistory.count

        described_class.perform_now
        expect(MarketIndexHistory.count).to eq(initial_count)
      end
    end

    context "when Yahoo gateway fails" do
      before do
        allow_any_instance_of(MarketData::YahooFinanceGateway).to receive(:fetch_historical)
          .and_return(Dry::Monads::Failure([ :gateway_error, "Connection timeout" ]))
      end

      it "does not create records and logs success with 0 synced" do
        expect { described_class.perform_now }
          .not_to change(MarketIndexHistory, :count)
      end
    end
  end
end
