require "rails_helper"

# The schedule is data, so nothing but a spec reads it the way Solid Queue will:
# through Fugit, on a server whose clock is UTC.
RSpec.describe "config/recurring.yml" do
  let(:tasks) { YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production") }

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
