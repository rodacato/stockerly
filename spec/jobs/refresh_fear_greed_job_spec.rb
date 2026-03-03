require "rails_helper"

RSpec.describe RefreshFearGreedJob, type: :job do
  describe "#perform" do
    context "when both APIs succeed" do
      before do
        stub_crypto_fear_greed
        stub_stock_fear_greed
      end

      it "creates two FearGreedReading records" do
        expect {
          described_class.perform_now
        }.to change(FearGreedReading, :count).by(2)
      end

      it "creates crypto and stocks readings" do
        described_class.perform_now

        crypto = FearGreedReading.crypto.last
        expect(crypto.value).to eq(25)
        expect(crypto.classification).to eq("Extreme Fear")
        expect(crypto.source).to eq("alternative.me")

        stocks = FearGreedReading.stocks.last
        expect(stocks.value).to eq(62)
        expect(stocks.classification).to eq("Greed")
        expect(stocks.source).to eq("cnn")
      end

      it "publishes FearGreedUpdated events" do
        events = []
        EventBus.subscribe(MarketData::Events::FearGreedUpdated, ->(event) { events << event })

        described_class.perform_now

        expect(events.size).to eq(2)
        expect(events.map { |e| e.is_a?(Hash) ? e[:index_type] : e.index_type }).to contain_exactly("crypto", "stocks")
      end

      it "logs success for each source" do
        expect {
          described_class.perform_now
        }.to change(SystemLog, :count).by(2)
      end
    end

    context "when crypto API fails but stocks succeeds" do
      before do
        stub_crypto_fear_greed_server_error
        stub_stock_fear_greed
      end

      it "still creates a stocks reading" do
        expect {
          described_class.perform_now
        }.to change(FearGreedReading, :count).by(1)

        expect(FearGreedReading.last.index_type).to eq("stocks")
      end

      it "logs failure for crypto and success for stocks" do
        described_class.perform_now

        logs = SystemLog.order(:created_at).last(2)
        expect(logs.first.task_name).to eq("Fear & Greed: crypto")
        expect(logs.first.severity).to eq("error")
        expect(logs.last.task_name).to eq("Fear & Greed: stocks")
        expect(logs.last.severity).to eq("success")
      end
    end

    context "when stocks API fails but crypto succeeds" do
      before do
        stub_crypto_fear_greed
        stub_stock_fear_greed_server_error
      end

      it "still creates a crypto reading" do
        expect {
          described_class.perform_now
        }.to change(FearGreedReading, :count).by(1)

        expect(FearGreedReading.last.index_type).to eq("crypto")
      end
    end

    context "when rate limited" do
      before do
        stub_crypto_fear_greed_rate_limited
        stub_stock_fear_greed_rate_limited
      end

      it "logs with warning severity" do
        described_class.perform_now

        logs = SystemLog.last(2)
        expect(logs).to all(have_attributes(severity: "warning"))
      end
    end
  end
end
