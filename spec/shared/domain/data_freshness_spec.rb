require "rails_helper"

RSpec.describe DataFreshness do
  include ActiveSupport::Testing::TimeHelpers

  # Thursday 17:00 UTC: 13:00 ET and 11:00 CDMX, both sessions well past the
  # opening grace, so every market-gated price check is actually evaluated.
  let(:session) { Time.utc(2026, 9, 3, 17, 0, 0) }

  describe ".newest_data_age_seconds" do
    it "returns the age in seconds of the most recently synced source" do
      create(:asset, sync_status: :active, price_updated_at: 5.minutes.ago)
      SystemLog.create!(task_name: "FX Rate Refresh", module_name: "sync", severity: :success,
                        duration_seconds: 0, created_at: 3.hours.ago)

      age = described_class.newest_data_age_seconds

      expect(age).to be_within(2).of(5.minutes.to_i)
    end

    it "returns nil when nothing has synced yet" do
      expect(described_class.newest_data_age_seconds).to be_nil
    end

    it "ignores assets that are not actively synced" do
      create(:asset, sync_status: :disabled, price_updated_at: 1.minute.ago)

      expect(described_class.newest_data_age_seconds).to be_nil
    end
  end

  describe ".checks" do
    # The defect this file exists for (#553): `maximum(:price_updated_at)` over
    # every active asset let the 24/7 crypto sync answer for the equities.
    it "reports a stale asset class even while another class is live" do
      travel_to(session) do
        create(:asset, :crypto, price_updated_at: 1.minute.ago)
        create(:asset, price_updated_at: 3.hours.ago, country: "US")

        checks = described_class.checks

        expect(checks[:prices_crypto]).to eq("ok")
        expect(checks[:prices_us]).to eq("critical")
        expect(described_class.overall_status(checks)).to eq("critical")
      end
    end

    it "keeps the BMV and US routes apart" do
      travel_to(session) do
        create(:asset, price_updated_at: 1.minute.ago, country: "US")
        create(:asset, price_updated_at: 3.hours.ago, country: "MX", exchange: "BMV")

        checks = described_class.checks

        expect(checks[:prices_us]).to eq("ok")
        expect(checks[:prices_mx]).to eq("critical")
      end
    end

    it "counts an asset with no country on the US route" do
      travel_to(session) do
        create(:asset, price_updated_at: 3.hours.ago, country: nil)

        expect(described_class.checks[:prices_us]).to eq("critical")
      end
    end

    it "flags a source as degraded past its ok threshold" do
      travel_to(session) do
        create(:asset, price_updated_at: 30.minutes.ago, country: "US")

        expect(described_class.checks[:prices_us]).to eq("degraded")
      end
    end

    # Overnight nothing is scheduled to update a US equity, so the silence is
    # not a fault and the check must not read it as one.
    it "does not judge a market-gated route while its session is closed" do
      travel_to(Time.utc(2026, 9, 3, 3, 0, 0)) do
        create(:asset, price_updated_at: 12.hours.ago, country: "US")

        expect(described_class.checks[:prices_us]).to eq("ok")
      end
    end

    # 09:45 ET: every price is yesterday's close because the first sync of the
    # session has barely had its turn.
    it "does not judge a route inside the opening grace" do
      travel_to(Time.utc(2026, 9, 3, 13, 45, 0)) do
        create(:asset, price_updated_at: 18.hours.ago, country: "US")

        expect(described_class.checks[:prices_us]).to eq("ok")
      end
    end

    # The factory pauses fixed income; a seeded instance does not — SeedAssets
    # and EnsureListed both list CETES as active, and SyncCetesJob refreshes
    # them weekly.
    it "gives CETES the weekly window its auction cadence earns" do
      travel_to(session) do
        create(:asset, :fixed_income, sync_status: :active, price_updated_at: 3.days.ago)

        expect(described_class.checks[:prices_fixed_income]).to eq("ok")
      end
    end

    it "flags CETES that have missed more than one weekly auction" do
      travel_to(session) do
        create(:asset, :fixed_income, sync_status: :active, price_updated_at: 10.days.ago)

        expect(described_class.checks[:prices_fixed_income]).to eq("critical")
      end
    end

    # Nothing on the schedule refreshes an index asset; the VIX level the app
    # reads is a MarketIndex row. Watching the seeded asset would be a check
    # that can only be red.
    it "does not watch index assets" do
      travel_to(session) do
        create(:asset, :index, price_updated_at: 1.year.ago)

        expect(described_class.checks.keys).not_to include(:prices_index)
        expect(described_class.overall_status).to eq("ok")
      end
    end

    # This read asked for "FX Rates Sync", a name nothing writes, so it found
    # nil no matter how long the refresh had been dead and /health reported FX
    # healthy on that basis. Before the fix this example read "ok".
    it "ages the FX check off the log RefreshFxRatesJob actually writes" do
      SystemLog.create!(task_name: "FX Rate Refresh", module_name: "sync", severity: :success,
                        duration_seconds: 0, created_at: 3.hours.ago)

      expect(described_class.checks[:fx_rates]).to eq("degraded")
    end

    # Deliberate: nil now means "this instance has never had a successful
    # refresh", which on first boot is true and not a fault. A long-running
    # instance that stops refreshing keeps its last success and ages into
    # degraded, and CheckSyncHealthJob is what watches for the silence itself.
    it "reports ok when a source has no data" do
      expect(described_class.checks[:fx_rates]).to eq("ok")
    end
  end

  describe ".overall_status" do
    it "is critical when any check is critical" do
      checks = { prices_us: "ok", indices: "critical", fx_rates: "degraded" }

      expect(described_class.overall_status(checks)).to eq("critical")
    end

    it "is degraded when a check is degraded and none critical" do
      checks = { prices_us: "ok", indices: "degraded", fx_rates: "ok" }

      expect(described_class.overall_status(checks)).to eq("degraded")
    end

    it "is ok when all checks pass" do
      checks = { prices_us: "ok", indices: "ok", fx_rates: "ok" }

      expect(described_class.overall_status(checks)).to eq("ok")
    end
  end
end
