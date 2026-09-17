require "rails_helper"
require "fugit"

# The schedule is data, so nothing but a spec reads it the way Solid Queue will:
# through Fugit, on a server whose clock is UTC.
RSpec.describe "config/recurring.yml" do
  let(:tasks) { YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production") }

  def next_run_in_mexico_city(key, after:)
    Fugit.parse(tasks.fetch(key).fetch("schedule")).next_time(after).to_t.in_time_zone("America/Mexico_City")
  end

  # `at 7am` on a UTC server is 01:00 in Mexico City, which is when these went out.
  %w[notify_earnings notify_maturities evaluate_date_based_alerts].each do |key|
    it "sends #{key} in the Mexico City morning" do
      run = next_run_in_mexico_city(key, after: Time.utc(2026, 9, 17, 0, 0))

      expect(run.hour).to eq(7)
    end
  end

  def detector_runs(calendar)
    tasks.values.select { |t| t["class"] == "DetectTechnicalObservationsJob" && t["args"] == [ calendar ] }
  end

  # D126: stocks, ETFs and indices after the BMV and the NYSE have both closed,
  # whatever US daylight time does — 15:00 CDMX is the later of the two closes.
  it "detects equity signals at 15:30 CDMX on weekdays" do
    run = detector_runs("equities").sole
    after_close = Fugit.parse(run["schedule"]).next_time(Time.utc(2026, 9, 17, 12)).to_t.in_time_zone("America/Mexico_City")

    expect([ after_close.hour, after_close.min ]).to eq([ 15, 30 ])
    expect(Fugit.parse(run["schedule"]).next_time(Time.utc(2026, 9, 19, 12)).to_t.in_time_zone("America/Mexico_City").wday).to eq(1)
  end

  # Crypto's day is the UTC day; its run starts once that day has ended.
  it "detects crypto signals just past the UTC day" do
    run = detector_runs("crypto").sole
    next_run = Fugit.parse(run["schedule"]).next_time(Time.utc(2026, 9, 17, 12)).to_t.utc

    expect([ next_run.hour, next_run.min ]).to eq([ 0, 15 ])
  end

  # Negative: the one nightly run for everything is gone.
  it "runs no detector without a calendar" do
    runs = tasks.values.select { |t| t["class"] == "DetectTechnicalObservationsJob" }

    expect(runs.pluck("args")).to contain_exactly([ "equities" ], [ "crypto" ])
  end

  # A held ETF used to refresh every 30 minutes while a held stock refreshed every 5.
  it "syncs held, followed and alerted ETFs on the stocks' high-priority cadence" do
    etf_high = tasks.values.find { |t| t["class"] == "SyncPriorityAssetsJob" && t["args"] == %w[etf high] }
    stock_high = tasks.values.find { |t| t["class"] == "SyncPriorityAssetsJob" && t["args"] == %w[stock high] }

    expect(etf_high&.fetch("schedule")).to eq(stock_high.fetch("schedule"))
  end

  # Negative: the ETFs nobody holds or follows keep the slower cadence.
  it "keeps the remaining ETFs on the low-priority cadence" do
    etf_low = tasks.values.find { |t| t["class"] == "SyncPriorityAssetsJob" && t["args"] == %w[etf low] }

    expect(etf_low&.fetch("schedule")).to eq("every 30 minutes")
    expect(tasks.values).not_to include(hash_including("args" => %w[etf all]))
  end
end
