require "rails_helper"

RSpec.describe CheckSyncHealthJob, type: :job do
  # Test env uses :null_store (config/environments/test.rb), so swap in an
  # in-memory store so the dedup spec can actually observe a cache hit/miss.
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    allow(Sentry).to receive(:capture_message)
  end

  def make_log(task_name, severity:, at: Time.current, message: nil)
    SystemLog.create!(
      task_name: task_name,
      module_name: "sync",
      severity: severity,
      error_message: message
    ).tap { |log| log.update_column(:created_at, at) }
  end

  describe "constants" do
    it "monitors the 8 critical sync task names exactly as logged by sync jobs" do
      expect(described_class::CRITICAL_SYNCS).to contain_exactly(
        "FX Rate Refresh",
        "Bulk Stock Sync",
        "Bulk BMV Sync",
        "Bulk Crypto Sync",
        "News Sync",
        "Earnings Sync",
        "CETES Sync",
        "Market Indices Sync"
      )
    end
  end

  describe "#perform" do
    context "when every monitored sync has at least one recent success" do
      before do
        described_class::CRITICAL_SYNCS.each do |task|
          make_log(task, severity: :success, at: 30.minutes.ago)
        end
      end

      it "fires no Sentry alerts" do
        described_class.new.perform
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when a sync has errors and no successes in the 25h window" do
      before do
        make_log("FX Rate Refresh", severity: :error, at: 2.hours.ago, message: "ExchangeRate 503")
      end

      it "fires exactly one Sentry warning for that sync" do
        described_class.new.perform

        expect(Sentry).to have_received(:capture_message).with(
          "Sync failing: FX Rate Refresh",
          hash_including(level: :warning)
        ).once
      end

      it "passes diagnostic context in :extra" do
        described_class.new.perform

        expect(Sentry).to have_received(:capture_message).with(
          "Sync failing: FX Rate Refresh",
          hash_including(
            extra: hash_including(
              task_name: "FX Rate Refresh",
              last_error_message: "ExchangeRate 503",
              last_success_at: nil
            )
          )
        )
      end
    end

    context "when multiple syncs are failing independently" do
      before do
        make_log("News Sync",   severity: :error, at: 1.hour.ago,  message: "NewsAPI 429")
        make_log("CETES Sync",  severity: :error, at: 3.hours.ago, message: "Banxico timeout")
      end

      it "fires one Sentry warning per affected sync" do
        described_class.new.perform

        expect(Sentry).to have_received(:capture_message).with(
          "Sync failing: News Sync", hash_including(level: :warning)
        ).once
        expect(Sentry).to have_received(:capture_message).with(
          "Sync failing: CETES Sync", hash_including(level: :warning)
        ).once
      end
    end

    context "when an error is followed by a more recent success (cured)" do
      before do
        make_log("Bulk Stock Sync", severity: :error,   at: 10.hours.ago, message: "AlphaVantage 500")
        make_log("Bulk Stock Sync", severity: :success, at: 1.hour.ago)
      end

      it "fires no Sentry alert (recent success cures the prior error)" do
        described_class.new.perform
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when errors are older than the 25h lookback window" do
      before do
        make_log("Earnings Sync", severity: :error, at: 26.hours.ago, message: "stale")
      end

      it "ignores the old failure (out of window)" do
        described_class.new.perform
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "dedup via Solid Cache" do
      before do
        make_log("Market Indices Sync", severity: :error, at: 1.hour.ago, message: "Polygon 502")
      end

      it "fires only once across two consecutive runs within the 6h dedup window" do
        described_class.new.perform
        described_class.new.perform

        expect(Sentry).to have_received(:capture_message).with(
          "Sync failing: Market Indices Sync", hash_including(level: :warning)
        ).once
      end

      it "fires again after the dedup TTL expires" do
        described_class.new.perform

        # Simulate TTL elapsing — clear the cache entry as if 6h+ had passed.
        Rails.cache.delete("sync_health_alert:Market Indices Sync")

        described_class.new.perform

        expect(Sentry).to have_received(:capture_message).with(
          "Sync failing: Market Indices Sync", hash_including(level: :warning)
        ).twice
      end
    end

    context "when Sentry raises during capture" do
      before do
        make_log("News Sync", severity: :error, at: 1.hour.ago, message: "boom")
        allow(Sentry).to receive(:capture_message).and_raise(StandardError, "sentry down")
      end

      it "swallows the error so the job keeps running for other syncs" do
        expect { described_class.new.perform }.not_to raise_error
      end
    end

    context "when there are no SystemLog entries at all (cold start)" do
      it "fires no Sentry alerts (silent ≠ failing)" do
        described_class.new.perform
        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end
end
