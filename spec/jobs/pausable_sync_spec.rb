require "rails_helper"

# D17: this switch was written by the settings screen and read by nothing.
RSpec.describe PausableSync do
  # Exercises the concern itself rather than guessing at any one job's internals.
  let(:probe) do
    Class.new(ApplicationJob) do
      include PausableSync
      cattr_accessor :ran
      def perform = self.class.ran = true
    end.tap { |klass| stub_const("PausableProbeJob", klass) }
  end

  before { probe.ran = false }

  it "skips the job when auto sync is off" do
    SiteConfig.set("auto_sync_enabled", false)

    probe.perform_now

    expect(probe.ran).to be(false)
  end

  it "runs the job when auto sync is on" do
    SiteConfig.set("auto_sync_enabled", true)

    probe.perform_now

    expect(probe.ran).to be(true)
  end

  # The dangerous default: an instance that predates the wiring has no row, and
  # reading that as "off" would silently stop every sync it has.
  it "defaults to on when the setting was never touched" do
    expect(SiteConfig.where(key: "auto_sync_enabled")).to be_empty

    probe.perform_now

    expect(probe.ran).to be(true)
  end

  it "leaves local computation running — with no new data it is a no-op anyway" do
    expect(CalculateTrendScoresJob.included_modules).not_to include(described_class)
    expect(TakeSnapshotsJob.included_modules).not_to include(described_class)
    expect(DetectTechnicalObservationsJob.included_modules).not_to include(described_class)
  end

  it "leaves notification jobs running — they are not what this switch names" do
    expect(SendDailyDigestJob.included_modules).not_to include(described_class)
    expect(NotifyEarningsJob.included_modules).not_to include(described_class)
  end

  it "guards every job that fetches, and only those" do
    fetching = Dir.glob("app/jobs/{sync,refresh,backfill}*_job.rb").map do |path|
      File.basename(path, ".rb").camelize.constantize
    end

    expect(fetching).to all(have_attributes(included_modules: include(described_class)))
    expect(fetching.size).to eq(25)
  end
end
