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
