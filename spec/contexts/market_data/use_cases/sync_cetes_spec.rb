require "rails_helper"

RSpec.describe MarketData::UseCases::SyncCetes do
  subject(:use_case) { described_class.new }

  before do
    create(:integration, provider_name: "Banxico", pool_key_value: "test_key")
  end

  describe "#call" do
    it "syncs CETES assets and publishes CetesSynced" do
      stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
      stub_banxico_auctions(term: "91", yield_rate: 11.20, date: "25/02/2026")
      stub_banxico_auctions(term: "182", yield_rate: 11.30, date: "25/02/2026")
      stub_banxico_auctions(term: "364", yield_rate: 11.45, date: "25/02/2026")
      allow(EventBus).to receive(:publish)

      result = use_case.call

      expect(result).to be_success
      expect(result.value!).to eq(4)
      expect(Asset.fixed_incomes.count).to eq(4)
      expect(Asset.find_by(symbol: "CETES_28D").yield_rate.to_f).to eq(11.15)
      expect(EventBus).to have_received(:publish).with(an_instance_of(MarketData::Events::CetesSynced))
    end

    it "does NOT set Asset.maturity_date — that's lot-level on Position (#29)" do
      stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
      stub_banxico_not_found(term: "91")
      stub_banxico_not_found(term: "182")
      stub_banxico_not_found(term: "364")
      allow(EventBus).to receive(:publish)

      use_case.call

      cetes_asset = Asset.find_by(symbol: "CETES_28D")
      expect(cetes_asset.maturity_date).to be_nil
    end

    it "leaves an existing Asset.maturity_date untouched (sync is idempotent on the field)" do
      # Backfill safety: if a previous sync (pre-#29) wrote a maturity, the new
      # sync neither rewrites it nor clears it — it simply doesn't touch the
      # column. This matters because Asset.maturity_date is still read by
      # asset_detail views as a fallback display for newly-listed instruments.
      preexisting = create(:asset, :fixed_income, symbol: "CETES_28D", maturity_date: 14.days.from_now.to_date)
      stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
      stub_banxico_not_found(term: "91")
      stub_banxico_not_found(term: "182")
      stub_banxico_not_found(term: "364")
      allow(EventBus).to receive(:publish)

      use_case.call

      expect(preexisting.reload.maturity_date).to eq(14.days.from_now.to_date)
    end

    it "skips terms when gateway returns failure" do
      stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
      stub_banxico_not_found(term: "91")
      stub_banxico_not_found(term: "182")
      stub_banxico_not_found(term: "364")
      allow(EventBus).to receive(:publish)

      result = use_case.call

      expect(result).to be_success
      expect(result.value!).to eq(1)
      expect(Asset.fixed_incomes.count).to eq(1)
    end
  end
end
