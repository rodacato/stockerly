require "rails_helper"

RSpec.describe CheckSyncHealthJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  # Wednesday 11:00 ET / 10:00 CST — both sessions open, both more than an hour
  # in. The market-gated watches are only evaluated then, so without pinning the
  # clock every spec about them would pass or fail by the hour it ran at.
  BOTH_MARKETS_OPEN = "2026-01-14 11:00:00 -0500".freeze

  # Test env uses :null_store (config/environments/test.rb), so swap in an
  # in-memory store so the dedup spec can actually observe a cache hit/miss.
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    travel_to(Time.zone.parse(BOTH_MARKETS_OPEN)) { example.run }
  ensure
    Rails.cache = original_cache
  end

  # The alert is what the owner can actually see: a health row in Registros and
  # a notification. Counting those is counting the alert.
  def health_alerts(task_name = nil)
    scope = SystemLog.where(module_name: "health")
    task_name ? scope.where(task_name: task_name) : scope
  end

  # Absence now alerts, so a spec about one sync has to say the others are fine
  # or it measures every unmonitored name at once.
  def silence_other_syncs(except:)
    (described_class::CRITICAL_SYNCS - Array(except)).each do |name|
      make_log(name, severity: :success, at: 1.hour.ago)
    end
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
    it "monitors the 7 critical sync task names exactly as logged by sync jobs" do
      expect(described_class::CRITICAL_SYNCS).to contain_exactly(
        "FX Rate Refresh",
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

      it "raises no alert" do
        described_class.new.perform
        expect(health_alerts).to be_empty
      end
    end

    context "when a sync has errors and no successes in the 25h window" do
      before do
        make_log("FX Rate Refresh", severity: :error, at: 2.hours.ago, message: "ExchangeRate 503")
      end

      it "raises exactly one alert for that sync" do
        described_class.new.perform

        expect(health_alerts("FX Rate Refresh").count).to eq(1)
      end

      it "carries the last error into the alert, which is the diagnostic part" do
        described_class.new.perform

        expect(health_alerts("FX Rate Refresh").sole.error_message)
          .to include("ExchangeRate 503").and include("hace más de 25 h")
      end
    end

    context "when multiple syncs are failing independently" do
      before do
        make_log("News Sync",   severity: :error, at: 1.hour.ago,  message: "NewsAPI 429")
        make_log("CETES Sync",  severity: :error, at: 3.hours.ago, message: "Banxico timeout")
      end

      it "raises one alert per affected sync" do
        described_class.new.perform

        expect(health_alerts("News Sync").count).to eq(1)
        expect(health_alerts("CETES Sync").count).to eq(1)
      end
    end

    context "when an error is followed by a more recent success (cured)" do
      before do
        silence_other_syncs(except: "Bulk BMV Sync")
        make_log("Bulk BMV Sync", severity: :error,   at: 10.hours.ago, message: "AlphaVantage 500")
        make_log("Bulk BMV Sync", severity: :success, at: 1.hour.ago)
      end

      it "raises no alert (recent success cures the prior error)" do
        described_class.new.perform
        expect(health_alerts).to be_empty
      end
    end

    context "when errors are older than the 25h lookback window" do
      before do
        silence_other_syncs(except: "Earnings Sync")
        make_log("Earnings Sync", severity: :error, at: 26.hours.ago, message: "stale")
      end

      # Out of window means unobserved, not healthy — the alert now says so, and
      # says it without an error to point at.
      it "alerts on the absence rather than on the stale failure" do
        described_class.new.perform

        entry = health_alerts("Earnings Sync").sole
        expect(entry.error_message).to include("Sin registros en la ventana")
      end
    end

    context "dedup via Solid Cache" do
      before do
        make_log("Market Indices Sync", severity: :error, at: 1.hour.ago, message: "Yahoo Finance 502")
      end

      it "alerts only once across two consecutive runs within the 6h dedup window" do
        described_class.new.perform
        described_class.new.perform

        expect(health_alerts("Market Indices Sync").count).to eq(1)
      end

      it "fires again after the dedup TTL expires" do
        described_class.new.perform

        # Simulate TTL elapsing — clear the cache entry as if 6h+ had passed.
        Rails.cache.delete("sync_health_alert:Market Indices Sync")

        described_class.new.perform

        expect(health_alerts("Market Indices Sync").count).to eq(2)
      end
    end

    # The only channel that can realistically fail is the one that crosses a
    # context boundary, so that is where the resilience guarantee is exercised.
    context "when a channel fails" do
      before do
        make_log("News Sync", severity: :error, at: 1.hour.ago, message: "boom")
        allow(Notifications::UseCases::CreateNotification)
          .to receive(:call).and_raise(StandardError, "notifications down")
      end

      it "swallows the error so the job keeps running for other syncs" do
        expect { described_class.new.perform }.not_to raise_error
      end
    end

    context "when there are no SystemLog entries at all (cold start)" do
      it "alerts on every monitored sync, because silence is unobserved, not healthy" do
        described_class.new.perform

        expect(health_alerts.pluck(:task_name)).to match_array(described_class::CRITICAL_SYNCS)
      end
    end

    # The false alarms #504 measured. Each one was a real notification the owner
    # received on a day when nothing was wrong, and an alert channel that cries
    # wolf on a Saturday is one that gets muted by December.
    describe "syncs that do not run daily and unconditionally" do
      # The BMV closed Friday at 15:00 CST and reopens Monday. Under one 25h
      # window the last success expired Saturday evening, so every weekend
      # produced "Tus acciones mexicanas no se han actualizado".
      it "stays quiet on Saturday for the syncs that only run while a market is open" do
        make_log("Bulk BMV Sync", severity: :success, at: Time.zone.parse("2026-01-16 15:00:00 -0600"))
        make_log("Market Indices Sync", severity: :success, at: Time.zone.parse("2026-01-16 16:00:00 -0500"))

        travel_to Time.zone.parse("2026-01-17 12:00:00 -0500")
        described_class.new.perform

        expect(health_alerts("Bulk BMV Sync")).to be_empty
        expect(health_alerts("Market Indices Sync")).to be_empty
      end

      # Same defect, weekday shape: at 07:00 ET neither market has opened, so
      # overnight silence is the schedule working, not the sync dying.
      it "stays quiet before the opening bell on a weekday" do
        travel_to Time.zone.parse("2026-01-14 07:00:00 -0500")
        described_class.new.perform

        expect(health_alerts("Bulk BMV Sync")).to be_empty
        expect(health_alerts("Market Indices Sync")).to be_empty
      end

      # Fifteen minutes after the bell a sync on a 30-minute cadence may
      # legitimately not have run yet. Alerting there just moves the false
      # alarm from Saturday to 09:45 every weekday.
      it "waits out the first hour of the session before reading silence as failure" do
        travel_to Time.zone.parse("2026-01-14 09:45:00 -0500")
        described_class.new.perform

        expect(health_alerts("Bulk BMV Sync")).to be_empty
      end

      # And the gate must not become a mute button: an hour into the session,
      # nothing logged is a real failure and still has to reach the owner.
      it "alerts once the session is underway and the sync still has nothing to show" do
        make_log("Bulk BMV Sync", severity: :error, at: 2.hours.ago, message: "DataBursatil 500")

        described_class.new.perform

        expect(health_alerts("Bulk BMV Sync").sole.error_message).to include("DataBursatil 500")
      end

      # US DST pulls the two sessions apart: at 16:30 ET the US has closed but
      # the BMV trades until 17:00 ET, and the indices job runs for either one.
      it "evaluates the indices while only the Mexican session is open" do
        travel_to Time.zone.parse("2026-07-15 16:30:00 -0400")
        described_class.new.perform

        expect(health_alerts("Market Indices Sync").count).to eq(1)
      end

      # CETES is auctioned weekly and synced Sunday at 10:00. Against a 25h
      # window it looked dead from Monday evening onwards — six days in seven.
      it "stays quiet six days after the weekly CETES sync succeeded" do
        silence_other_syncs(except: "CETES Sync")
        make_log("CETES Sync", severity: :success, at: 6.days.ago)

        described_class.new.perform

        expect(health_alerts).to be_empty
      end

      # Past two missed auctions it is genuinely dead, and the nine-day window
      # is only worth having if it still says so.
      it "alerts when the weekly CETES sync has missed more than one auction" do
        silence_other_syncs(except: "CETES Sync")
        make_log("CETES Sync", severity: :success, at: 10.days.ago)

        described_class.new.perform

        expect(health_alerts("CETES Sync").sole.error_message).to include("más de 9 días")
      end
    end
  end
  describe "telling the owner" do
    let!(:owner) { create(:user) }

    before do
      silence_other_syncs(except: "Bulk BMV Sync")
      make_log("Bulk BMV Sync", severity: :error, at: 2.hours.ago, message: "DataBursatil: rate_limited (HTTP 429)")
    end

    # The owner is the person whose data went stale, and the notification is the
    # only channel that goes looking for them.
    it "creates one notification for the owner, in their own terms" do
      expect { described_class.perform_now }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.notification_type).to eq("system")
      expect(notification.title).to eq("Tus acciones mexicanas no se han actualizado en más de un día")
      expect(notification.body).to include("HTTP 429").and include("Registros")
    end

    # The individual errors are already in Registros; this row is the pattern
    # over them, which is what the notification points back to.
    it "records the pattern as its own log entry" do
      described_class.perform_now

      entry = SystemLog.where(module_name: "health").last
      expect(entry.task_name).to eq("Bulk BMV Sync")
      expect(entry.severity).to eq("error")
    end

    it "rides the existing dedup rather than re-notifying every hour" do
      described_class.perform_now

      expect { described_class.perform_now }.not_to change(Notification, :count)
    end

    it "records the pattern as well as notifying — the two readers are not duplicates" do
      described_class.perform_now

      expect(Notification.count).to eq(1)
      expect(SystemLog.where(module_name: "health", task_name: "Bulk BMV Sync").count).to eq(1)
    end

    # A failure in the owner-facing half must not lose the written record.
    it "keeps the health record when the notification cannot be created" do
      allow(Notifications::UseCases::CreateNotification).to receive(:call).and_raise(StandardError, "boom")

      described_class.perform_now

      expect(SystemLog.where(module_name: "health", task_name: "Bulk BMV Sync").count).to eq(1)
    end

    it "says nothing when setup never ran and there is no owner" do
      User.delete_all

      expect { described_class.perform_now }.not_to change(Notification, :count)
    end
  end
end
