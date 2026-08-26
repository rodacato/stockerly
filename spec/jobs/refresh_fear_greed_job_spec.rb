require "rails_helper"

RSpec.describe RefreshFearGreedJob, type: :job do
  describe "#perform" do
    context "when the API succeeds" do
      before { stub_crypto_fear_greed }

      it "creates a crypto reading" do
        expect {
          described_class.perform_now
        }.to change(FearGreedReading, :count).by(1)

        reading = FearGreedReading.crypto.last
        expect(reading.value).to eq(25)
        expect(reading.classification).to eq("Extreme Fear")
        expect(reading.source).to eq("alternative.me")
      end

      it "never creates a stocks reading — CNN's index is retired" do
        described_class.perform_now

        expect(FearGreedReading.where(index_type: "stocks")).to be_empty
      end

      it "publishes a FearGreedUpdated event" do
        events = []
        EventBus.subscribe(MarketData::Events::FearGreedUpdated, ->(event) { events << event })

        described_class.perform_now

        expect(events.size).to eq(1)
        expect(events.map { |e| e.is_a?(Hash) ? e[:index_type] : e.index_type }).to contain_exactly("crypto")
      end

      it "logs the success" do
        expect {
          described_class.perform_now
        }.to change(SystemLog, :count).by(1)
      end
    end

    context "when the API fails" do
      before { stub_crypto_fear_greed_server_error }

      it "creates no reading and logs the failure as an error" do
        expect {
          described_class.perform_now
        }.not_to change(FearGreedReading, :count)

        log = SystemLog.order(:created_at).last
        expect(log.task_name).to eq("Fear & Greed: crypto")
        expect(log.severity).to eq("error")
      end
    end

    context "when rate limited" do
      before { stub_crypto_fear_greed_rate_limited }

      it "logs with warning severity rather than error" do
        described_class.perform_now

        expect(SystemLog.order(:created_at).last.severity).to eq("warning")
      end
    end
  end
end
