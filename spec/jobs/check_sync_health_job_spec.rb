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

  def freshness_alerts(key)
    health_alerts("Freshness: #{key}")
  end

  # Absence alerts, so a spec about one watch has to say the others are fine or
  # it measures every unmonitored source at once. The four log-derived sources
  # need a success row; the price routes have nothing to be stale until the
  # example creates an asset.
  def silence_log_derived_sources(except: [])
    names = [ "News Sync", "Earnings Sync", "Market Indices Sync", "FX Rate Refresh" ] - Array(except)
    names.each { |name| make_log(name, severity: :success, at: 30.minutes.ago) }
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
    # Two syncs report counts, where zero new items is not an error, so the
    # success row is the only dated fact that means healthy. Everything else
    # reads DataFreshness.
    it "watches logs for the two syncs with no data threshold to read" do
      expect(described_class::LOG_WATCHES.values.pluck(:task_name))
        .to contain_exactly("News Sync", "Earnings Sync")
    end

    # The keys the job builds its i18n lookups from — freshness routes and log
    # watches alike. i18n-tasks cannot see a key assembled at runtime, so this
    # is the check that stands in for the scan.
    it "has owner-facing copy for every watch it can alert on" do
      keys = DataFreshness::CHECKS.keys + described_class::LOG_WATCHES.keys

      keys.each do |key|
        phrase = I18n.t("notificaciones.sincronizacion.titulo.#{key}", tiempo: "una hora")
        expect(phrase).not_to include("translation missing"), "no title copy for #{key}"
      end
    end
  end

  describe "#perform" do
    context "when every monitored source has recently reported" do
      before do
        silence_log_derived_sources
        create(:asset, country: "US", price_updated_at: 1.minute.ago)
        create(:asset, :mexican, price_updated_at: 1.minute.ago)
        create(:asset, :crypto, price_updated_at: 1.minute.ago)
      end

      it "raises no alert" do
        described_class.new.perform
        expect(health_alerts).to be_empty
      end
    end

    # The gap #504 opened with: SyncPriorityAssetsJob fans out one job per
    # ticker and writes no summary row, so no log watch could ever cover the US
    # feed. Freshness reads the prices themselves.
    context "when the US price feed is dead" do
      let!(:owner) { create(:user) }

      before do
        silence_log_derived_sources
        create(:asset, country: "US", price_updated_at: 7.hours.ago)
      end

      it "notifies the owner" do
        expect { described_class.new.perform }.to change(Notification, :count).by(1)

        expect(Notification.last.title)
          .to eq("Tus acciones estadounidenses no se han actualizado en más de 6 horas")
      end

      it "records the finding without claiming a cause it cannot know" do
        described_class.new.perform

        entry = freshness_alerts(:prices_us).sole
        expect(entry.error_message).to eq("Los datos no se han actualizado desde hace más de 6 horas.")
        expect(Notification.last.body).to include("Registros")
      end
    end

    context "when a log-watched sync has errors and no successes in its window" do
      before { silence_log_derived_sources(except: "News Sync") }

      it "carries the last error into the alert, which is the diagnostic part" do
        make_log("News Sync", severity: :error, at: 2.hours.ago, message: "NewsAPI 429")

        described_class.new.perform

        expect(health_alerts("News Sync").sole.error_message)
          .to include("NewsAPI 429").and include("hace más de un día")
      end

      # Out of window means unobserved, not healthy — the alert says so, and
      # says it without an error to point at.
      it "alerts on the absence when the failure is older than the window" do
        make_log("News Sync", severity: :error, at: 26.hours.ago, message: "stale")

        described_class.new.perform

        expect(health_alerts("News Sync").sole.error_message).to include("Sin registros en la ventana")
      end

      it "raises no alert when a more recent success cures the prior error" do
        make_log("News Sync", severity: :error,   at: 10.hours.ago, message: "NewsAPI 429")
        make_log("News Sync", severity: :success, at: 1.hour.ago)

        described_class.new.perform

        expect(health_alerts).to be_empty
      end
    end

    # The measure moved to the data, so a sync that reports success while its
    # prices sit still no longer reads as healthy — and one that reports
    # nothing while the prices move no longer reads as broken.
    describe "freshness over logs for the five overlapping watches" do
      before { silence_log_derived_sources }

      it "alerts on stale BMV prices even though the sync logged a success" do
        create(:asset, :mexican, price_updated_at: 7.hours.ago)
        make_log("Bulk BMV Sync", severity: :success, at: 1.minute.ago)

        described_class.new.perform

        expect(freshness_alerts(:prices_mx).count).to eq(1)
      end

      it "stays quiet on fresh crypto prices even though the sync logged an error" do
        create(:asset, :crypto, price_updated_at: 1.minute.ago)
        make_log("Bulk Crypto Sync", severity: :error, at: 1.minute.ago, message: "CoinGecko 429")

        described_class.new.perform

        expect(health_alerts).to be_empty
      end

      # A route with nothing to refresh has nothing that can go stale. Alerting
      # that "tus criptomonedas" are old on an instance holding none is the
      # false alarm that teaches the owner to mute the channel.
      it "says nothing about an asset class the owner does not hold" do
        described_class.new.perform

        expect(health_alerts).to be_empty
      end
    end

    context "dedup via Solid Cache" do
      before do
        silence_log_derived_sources
        create(:asset, country: "US", price_updated_at: 7.hours.ago)
      end

      it "alerts only once across two consecutive runs within the 6h dedup window" do
        described_class.new.perform
        described_class.new.perform

        expect(freshness_alerts(:prices_us).count).to eq(1)
      end

      it "fires again after the dedup TTL expires" do
        described_class.new.perform

        # Simulate TTL elapsing — clear the cache entry as if 6h+ had passed.
        Rails.cache.delete("sync_health_alert:prices_us")

        described_class.new.perform

        expect(freshness_alerts(:prices_us).count).to eq(2)
      end
    end

    # The only channel that can realistically fail is the one that crosses a
    # context boundary, so that is where the resilience guarantee is exercised.
    context "when a channel fails" do
      before do
        silence_log_derived_sources(except: "News Sync")
        make_log("News Sync", severity: :error, at: 1.hour.ago, message: "boom")
        allow(Notifications::UseCases::CreateNotification)
          .to receive(:call).and_raise(StandardError, "notifications down")
      end

      it "swallows the error so the job keeps running for other syncs" do
        expect { described_class.new.perform }.not_to raise_error
      end
    end

    context "when nothing has ever reported (cold start)" do
      # Absence is unobserved, not healthy, for the sources whose only evidence
      # is a log row. The price routes stay quiet because an instance with no
      # assets has no prices that could be stale.
      it "alerts on every log-derived source and on none of the price routes" do
        described_class.new.perform

        expect(health_alerts.pluck(:task_name))
          .to contain_exactly("News Sync", "Earnings Sync", "Freshness: indices", "Freshness: fx_rates")
      end
    end

    # The false alarms #551 measured. Each one was a real notification the owner
    # received on a day when nothing was wrong, and an alert channel that cries
    # wolf on a Saturday is one that gets muted by December.
    describe "sources that do not run daily and unconditionally" do
      # The BMV closed Friday at 15:00 CST and reopens Monday; the NYSE closed
      # Friday at 16:00 ET. Nothing is scheduled to refresh either price over a
      # weekend, so the silence is the schedule working.
      it "stays quiet on Saturday for every market-gated source" do
        travel_to Time.zone.parse("2026-01-17 12:00:00 -0500")
        silence_log_derived_sources(except: "Market Indices Sync")
        create(:asset, :mexican, price_updated_at: Time.zone.parse("2026-01-16 15:00:00 -0600"))
        create(:asset, country: "US", price_updated_at: Time.zone.parse("2026-01-16 16:00:00 -0500"))
        make_log("Market Indices Sync", severity: :success, at: Time.zone.parse("2026-01-16 16:00:00 -0500"))

        described_class.new.perform

        expect(health_alerts).to be_empty
      end

      # Same defect, weekday shape: at 07:00 ET neither market has opened, so
      # overnight silence is not the sync dying.
      it "stays quiet before the opening bell on a weekday" do
        travel_to Time.zone.parse("2026-01-14 07:00:00 -0500")
        silence_log_derived_sources
        create(:asset, :mexican, price_updated_at: 18.hours.ago)
        create(:asset, country: "US", price_updated_at: 18.hours.ago)

        described_class.new.perform

        expect(health_alerts).to be_empty
      end

      # Fifteen minutes after the bell every price is still yesterday's close.
      # Alerting there just moves the false alarm from Saturday to 09:45.
      it "waits out the first hour of the session before reading silence as failure" do
        travel_to Time.zone.parse("2026-01-14 09:45:00 -0500")
        silence_log_derived_sources
        create(:asset, country: "US", price_updated_at: 18.hours.ago)

        described_class.new.perform

        expect(freshness_alerts(:prices_us)).to be_empty
      end

      # And the gate must not become a mute button: an hour into the session,
      # prices that have not moved are a real failure and still reach the owner.
      it "alerts once the session is underway and the prices still have not moved" do
        silence_log_derived_sources
        create(:asset, :mexican, price_updated_at: 18.hours.ago)

        described_class.new.perform

        expect(freshness_alerts(:prices_mx).count).to eq(1)
      end

      # US DST pulls the two sessions apart: at 16:30 ET the US has closed but
      # the BMV trades until 17:00 ET, and the indices job runs for either one.
      it "evaluates the indices while only the Mexican session is open" do
        travel_to Time.zone.parse("2026-07-15 16:30:00 -0400")
        silence_log_derived_sources(except: "Market Indices Sync")

        described_class.new.perform

        expect(freshness_alerts(:indices).count).to eq(1)
      end

      # CETES is auctioned weekly and synced Sunday at 10:00. Against a daily
      # window it looked dead from Monday evening onwards — six days in seven.
      it "stays quiet six days after the weekly CETES sync succeeded" do
        silence_log_derived_sources
        create(:asset, :fixed_income, sync_status: :active, price_updated_at: 6.days.ago)

        described_class.new.perform

        expect(health_alerts).to be_empty
      end

      # Past two missed auctions it is genuinely dead, and the nine-day window
      # is only worth having if it still says so.
      it "alerts when the weekly CETES sync has missed more than one auction" do
        silence_log_derived_sources
        create(:asset, :fixed_income, sync_status: :active, price_updated_at: 10.days.ago)

        described_class.new.perform

        expect(freshness_alerts(:prices_fixed_income).sole.error_message).to include("más de 9 días")
      end
    end

    # The defect #553 fixed on /health, asserted here on the channel that goes
    # looking for the owner: one live asset class must not answer for another.
    it "does not let a healthy asset class cure a stale one" do
      silence_log_derived_sources
      create(:asset, :crypto, price_updated_at: 1.minute.ago)
      create(:asset, country: "US", price_updated_at: 7.hours.ago)

      described_class.new.perform

      expect(freshness_alerts(:prices_crypto)).to be_empty
      expect(freshness_alerts(:prices_us).count).to eq(1)
    end
  end

  describe "telling the owner" do
    let!(:owner) { create(:user) }

    before do
      silence_log_derived_sources(except: "Earnings Sync")
      make_log("Earnings Sync", severity: :error, at: 2.hours.ago, message: "FMP: rate_limited (HTTP 429)")
    end

    # The owner is the person whose data went stale, and the notification is the
    # only channel that goes looking for them.
    it "creates one notification for the owner, in their own terms" do
      expect { described_class.perform_now }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.notification_type).to eq("system")
      expect(notification.title).to eq("El calendario de reportes no se ha actualizado en más de un día")
      expect(notification.body).to include("HTTP 429").and include("Registros")
    end

    # The individual errors are already in Registros; this row is the pattern
    # over them, which is what the notification points back to.
    it "records the pattern as its own log entry" do
      described_class.perform_now

      entry = health_alerts("Earnings Sync").sole
      expect(entry.severity).to eq("error")
    end

    it "rides the existing dedup rather than re-notifying every hour" do
      described_class.perform_now

      expect { described_class.perform_now }.not_to change(Notification, :count)
    end

    # A failure in the owner-facing half must not lose the written record.
    it "keeps the health record when the notification cannot be created" do
      allow(Notifications::UseCases::CreateNotification).to receive(:call).and_raise(StandardError, "boom")

      described_class.perform_now

      expect(health_alerts("Earnings Sync").count).to eq(1)
    end

    it "says nothing when setup never ran and there is no owner" do
      User.delete_all

      expect { described_class.perform_now }.not_to change(Notification, :count)
    end
  end
end
