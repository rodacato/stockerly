require "rails_helper"

RSpec.describe SyncBulkBmvJob, type: :job do
  before { create(:integration, provider_name: "DataBursatil", api_key_encrypted: "test_token") }

  describe "#perform" do
    let!(:genius) { create(:asset, :mexican, symbol: "GENIUSSACV.MX", current_price: 20.00, price_updated_at: 10.minutes.ago) }
    let!(:ivv) { create(:asset, :mexican, :etf, symbol: "IVVPESO.MX", current_price: 40.00, price_updated_at: 10.minutes.ago) }

    context "when DataBursatil returns valid data" do
      before do
        stub_databursatil("/v2/cotizaciones", {
          "GENIUSSACV" => { "bmv" => databursatil_quote(last: 25.50, change: 1.25, volume: 500_000) },
          "IVVPESO" => { "bmv" => databursatil_quote(last: 48.30, change: 0.75, volume: 200_000) }
        })
      end

      it "updates all BMV asset prices in a single API call" do
        described_class.perform_now([ genius.id, ivv.id ])

        genius.reload
        ivv.reload
        expect(genius.current_price.to_f).to eq(25.5)
        expect(ivv.current_price.to_f).to eq(48.3)
      end

      it "updates price_updated_at for each asset" do
        described_class.perform_now([ genius.id, ivv.id ])

        genius.reload
        expect(genius.price_updated_at).to be_within(2.seconds).of(Time.current)
      end

      it "publishes AssetPriceUpdated events for changed prices" do
        expect(EventBus).to receive(:publish).with(an_instance_of(MarketData::Events::AssetPriceUpdated)).twice

        described_class.perform_now([ genius.id, ivv.id ])
      end

      it "creates a success SystemLog entry" do
        expect {
          described_class.perform_now([ genius.id, ivv.id ])
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to include("Bulk BMV Sync")
      end
    end

    # Measured 2026-08-27 against the real provider: a name it does not
    # recognise is simply absent from the response and the batch still answers
    # 200 with the rest. #311 assumed the whole call failed; it does not. What
    # it does is go quiet, which is worse — the job logged "2 assets" having
    # priced one.
    context "when the provider has no quote for one of the issuers" do
      before do
        stub_databursatil("/v2/cotizaciones", {
          "GENIUSSACV" => { "bmv" => databursatil_quote(last: 21.50) }
        })
      end

      it "prices the one it can" do
        described_class.perform_now([ genius.id, ivv.id ])

        expect(genius.reload.current_price.to_f).to eq(21.50)
      end

      it "leaves the one it cannot alone rather than guessing" do
        described_class.perform_now([ genius.id, ivv.id ])

        expect(ivv.reload.current_price.to_f).to eq(40.00)
      end

      it "stops claiming it synced what it did not" do
        described_class.perform_now([ genius.id, ivv.id ])

        log = SystemLog.where(task_name: "Bulk BMV Sync").last
        expect(log.severity).to eq("warning")
        expect(log.error_message).to include("Priced 1 of 2").and include("IVVPESO")
        expect(log.error_message).to include("resolve_bmv_symbols")
      end
    end

    context "when DataBursatil is rate limited" do
      before { stub_databursatil("/v2/cotizaciones", {}, status: 429) }

      it "creates a warning SystemLog entry" do
        described_class.perform_now([ genius.id, ivv.id ])

        log = SystemLog.last
        expect(log.severity).to eq("warning")
      end
    end

    context "when no active assets found" do
      let!(:disabled) { create(:asset, :mexican, :disabled, symbol: "DISABLED.MX") }

      it "does nothing" do
        expect {
          described_class.perform_now([ disabled.id ])
        }.not_to change(SystemLog, :count)
      end
    end
  end
end
