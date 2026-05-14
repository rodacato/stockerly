require "rails_helper"
require "rake"

RSpec.describe "fx_rate_backfill rake tasks" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("fx_rate_backfill:trades")
  end

  before do
    Rake::Task["fx_rate_backfill:trades"].reenable
  end

  describe "fx_rate_backfill:trades" do
    let(:mx_user) { create(:user, preferred_currency: "MXN") }
    let(:portfolio) { create(:portfolio, user: mx_user) }
    let(:usd_asset) { create(:asset, :stock, symbol: "AAPL") }
    let(:mxn_asset) { create(:asset, :mexican, symbol: "WALMEX.MX") }

    it "fills NULL fx_rate_at_execution for same-currency trades with 1.0" do
      trade = create(:trade, portfolio: portfolio, asset: mxn_asset, currency: "MXN", fx_rate_at_execution: nil)

      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(trade.reload.fx_rate_at_execution).to eq(BigDecimal(1))
    end

    it "fills NULL fx_rate_at_execution for cross-currency trades using current FxRate" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD", fx_rate_at_execution: nil)

      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(trade.reload.fx_rate_at_execution).to eq(BigDecimal("17.5"))
    end

    it "is idempotent — skips rows already filled on a second run" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD", fx_rate_at_execution: nil)

      Rake::Task["fx_rate_backfill:trades"].invoke
      Rake::Task["fx_rate_backfill:trades"].reenable

      # On the second run there should be nothing to do; the rate stays the same
      # and no gateway calls are issued.
      expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)
      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(trade.reload.fx_rate_at_execution).to eq(BigDecimal("17.5"))
    end

    it "leaves trade unchanged and warns when the resolver fails" do
      trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD", fx_rate_at_execution: nil)
      gateway = instance_double(MarketData::Gateways::FxRatesGateway, refresh_rates: nil)
      allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)

      expect { Rake::Task["fx_rate_backfill:trades"].invoke }.to output(/skipped/).to_stderr

      expect(trade.reload.fx_rate_at_execution).to be_nil
    end

    it "caches resolution per (currency, preferred) pair across many trades" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      3.times { create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD", fx_rate_at_execution: nil) }

      # Even with multiple trades sharing (USD, MXN), the resolver should be called once.
      # We assert by counting gateway instantiations: forward FxRate exists, so 0 gateway calls.
      expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(Trade.where(fx_rate_at_execution: BigDecimal("17.5")).count).to eq(3)
    end
  end
end
