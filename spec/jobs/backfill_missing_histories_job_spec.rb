require "rails_helper"

RSpec.describe BackfillMissingHistoriesJob, type: :job do
  let!(:sparse_stock) { create(:asset, symbol: "SPARSE", asset_type: :stock, sync_status: :active) }
  let!(:full_stock) { create(:asset, symbol: "FULL", asset_type: :stock, sync_status: :active) }
  let!(:disabled_stock) { create(:asset, symbol: "OFF", asset_type: :stock, sync_status: :disabled) }

  before do
    histories_for(sparse_stock, described_class::MIN_HISTORIES - 1)
    histories_for(full_stock, described_class::MIN_HISTORIES)
  end

  def histories_for(asset, count)
    count.times { |i| create(:asset_price_history, asset: asset, date: i.days.ago.to_date) }
  end

  describe "#perform" do
    it "enqueues BackfillPriceHistoryJob for assets below #{described_class::MIN_HISTORIES} histories" do
      expect { described_class.perform_now }
        .to have_enqueued_job(BackfillPriceHistoryJob).with(sparse_stock.id)
    end

    it "does not enqueue for assets with sufficient histories" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(BackfillPriceHistoryJob).with(full_stock.id)
    end

    it "does not enqueue for disabled assets" do
      expect { described_class.perform_now }
        .not_to have_enqueued_job(BackfillPriceHistoryJob).with(disabled_stock.id)
    end

    it "staggers jobs with #{described_class::STAGGER_SECONDS}-second intervals" do
      sparse2 = create(:asset, symbol: "SPARSE2", asset_type: :stock, sync_status: :active)

      expect(BackfillPriceHistoryJob).to receive(:set).with(wait: 0.seconds).ordered.and_call_original
      expect(BackfillPriceHistoryJob).to receive(:set).with(wait: 5.seconds).ordered.and_call_original

      described_class.perform_now
    end

    it "is scheduled weekly on Sundays at 3am" do
      config = YAML.load_file(Rails.root.join("config/recurring.yml"))
      schedule = config.dig("production", "backfill_missing_histories", "schedule")

      expect(schedule).to eq("0 3 * * 0")
    end

    it "limits to #{described_class::MAX_ASSETS} assets" do
      expect(described_class::MAX_ASSETS).to eq(50)
    end

    it "requires enough history for the longest indicator window" do
      expect(described_class::MIN_HISTORIES).to be >= 200
      expect(described_class::MIN_HISTORIES).to be < BackfillPriceHistoryJob::DAYS * 5 / 7
    end

    it "logs success with count" do
      expect { described_class.perform_now }
        .to change { SystemLog.where(task_name: "Backfill Missing Histories", severity: :success).count }.by(1)
    end
  end
end
