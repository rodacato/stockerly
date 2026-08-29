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

    it "fills a cross-currency trade with the FIX of the day it executed" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: 10.days.ago.to_date, rate: 17.5, source: "banxico")
      trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD",
                             executed_at: 9.days.ago, fx_rate_at_execution: nil)

      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(trade.reload.fx_rate_at_execution).to eq(BigDecimal("17.5"))
    end

    # The whole reason the column exists: a backdated trade valued at today's
    # rate is the bug it was added to prevent.
    it "values each trade at its own date, not at today's rate" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: 30.days.ago.to_date, rate: 17.0, source: "banxico")
      FxRateHistory.record(base: "USD", quote: "MXN", date: Date.current, rate: 25.0, source: "banxico")
      old_trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD",
                                 executed_at: 29.days.ago, fx_rate_at_execution: nil)
      new_trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD",
                                 executed_at: Time.current, fx_rate_at_execution: nil)

      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(old_trade.reload.fx_rate_at_execution).to eq(BigDecimal("17.0"))
      expect(new_trade.reload.fx_rate_at_execution).to eq(BigDecimal("25.0"))
    end

    it "is idempotent — skips rows already filled on a second run" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: 10.days.ago.to_date, rate: 17.5, source: "banxico")
      trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD",
                             executed_at: 9.days.ago, fx_rate_at_execution: nil)

      2.times do
        Rake::Task["fx_rate_backfill:trades"].invoke
        Rake::Task["fx_rate_backfill:trades"].reenable
      end

      expect(trade.reload.fx_rate_at_execution).to eq(BigDecimal("17.5"))
    end

    it "leaves the trade null and warns when the series cannot answer for that date" do
      trade = create(:trade, portfolio: portfolio, asset: usd_asset, currency: "USD", fx_rate_at_execution: nil)

      expect { Rake::Task["fx_rate_backfill:trades"].invoke }.to output(/skipped/).to_stderr

      expect(trade.reload.fx_rate_at_execution).to be_nil
    end

    # Captured against MXN whatever the account prefers — the divergence #405
    # was filed for.
    it "captures against MXN even for a USD-preferring account" do
      FxRateHistory.record(base: "USD", quote: "MXN", date: 10.days.ago.to_date, rate: 17.5, source: "banxico")
      usd_portfolio = create(:portfolio, user: create(:user, preferred_currency: "USD"))
      trade = create(:trade, portfolio: usd_portfolio, asset: usd_asset, currency: "USD",
                             executed_at: 9.days.ago, fx_rate_at_execution: nil)

      Rake::Task["fx_rate_backfill:trades"].invoke

      expect(trade.reload.fx_rate_at_execution).to eq(BigDecimal("17.5"))
    end
  end
end
