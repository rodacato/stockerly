require "rails_helper"

RSpec.describe Trading::UseCases::ImportTrades do
  let(:user) { create(:user, preferred_currency: "USD") }
  let!(:portfolio) { create(:portfolio, user: user, inception_date: Date.current) }
  let!(:vt) { create(:asset, :etf, symbol: "VT", currency: "USD") }
  let!(:coin) { create(:asset, symbol: "COIN", currency: "USD") }

  let(:december) { "2025-12-08T06:57:37-05:00" }

  before do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 12, 1), rate: 18.2293, source: "banxico")
  end

  def row(overrides = {})
    {
      asset_symbol: "VT",
      side: "buy",
      shares: "0.070436076",
      price_per_share: "141.972700",
      fee: "0.0",
      currency: "USD",
      executed_at: december,
      external_id: "order-1",
      net_amount: "-10.00"
    }.merge(overrides)
  end

  describe "refusals" do
    it "refuses a row that does not state its currency, naming the row" do
      result = described_class.call(user: user, rows: [ row, row(currency: nil, external_id: "order-2") ])

      expect(result).to be_failure
      tag, invalid = result.failure
      expect(tag).to eq(:invalid_rows)
      expect(invalid.first[:row]).to eq(2)
      expect(invalid.first[:errors]).to have_key(:currency)
    end

    it "refuses the batch when a symbol is not in the catalogue, listing every one" do
      result = described_class.call(user: user, rows: [ row, row(asset_symbol: "NOPE", external_id: "o2"), row(asset_symbol: "ALSONOPE", external_id: "o3") ], dry_run: false)

      expect(result).to be_failure
      reason, symbols = result.failure
      expect(reason).to eq(:unknown_symbols)
      expect(symbols).to eq(%w[ALSONOPE NOPE])
      expect(Trade.count).to eq(0)
    end

    it "refuses a row whose net amount disagrees with shares x price" do
      result = described_class.call(user: user, rows: [ row(net_amount: "-99.00") ], dry_run: false)

      reason, details = result.failure
      expect(reason).to eq(:invalid_rows)
      expect(details.first[:errors][:net_amount].first).to match(/does not match shares x price/)
    end

    it "refuses a trade dated in the future" do
      result = described_class.call(user: user, rows: [ row(executed_at: 3.days.from_now.iso8601, net_amount: nil) ], dry_run: false)

      reason, details = result.failure
      expect(reason).to eq(:invalid_rows)
      expect(details.first[:errors][:executed_at].first).to match(/future/)
    end

    it "refuses fixed income, whose lots need a maturity the CSV cannot carry" do
      create(:asset, :fixed_income, symbol: "CETE28D")
      result = described_class.call(user: user, rows: [ row(asset_symbol: "CETE28D", currency: "MXN", net_amount: nil) ], dry_run: false)

      expect(result.failure).to eq([ :unsupported_asset_type, [ "CETE28D" ] ])
    end

    it "refuses when no historical rate exists on or before the trade date" do
      FxRateHistory.delete_all
      result = described_class.call(user: user, rows: [ row ], dry_run: false)

      reason, missing = result.failure
      expect(reason).to eq(:missing_fx_history)
      expect(missing.first).to match(/USD->MXN on 2025-12-08/)
    end

    it "refuses a sell that exceeds the shares on hand" do
      expect {
        described_class.call(user: user, rows: [ row(side: "sell", net_amount: nil) ], dry_run: false)
      }.to raise_error(ActiveRecord::RecordInvalid)
      expect(Trade.count).to eq(0)
    end
  end

  describe "dry run" do
    it "reports what would happen and writes nothing" do
      result = described_class.call(user: user, rows: [ row, row(asset_symbol: "COIN", shares: "0.036232711", price_per_share: "275.993700", external_id: "order-2") ])

      report = result.value!
      expect(report[:dry_run]).to be(true)
      expect(report[:imported]).to eq(2)
      expect(report[:symbols]).to eq(%w[COIN VT])
      expect(report[:invested].round(2)).to eq(BigDecimal("20.00"))
      expect(Trade.count).to eq(0)
      expect(Position.count).to eq(0)
    end
  end

  describe "committing" do
    it "creates the trades and the position" do
      described_class.call(user: user, rows: [ row ], dry_run: false)

      trade = Trade.sole
      expect(trade.external_id).to eq("order-1")
      expect(trade.shares).to eq(BigDecimal("0.070436"))
      expect(trade.position.shares).to eq(BigDecimal("0.070436"))
    end

    it "dates the position from the trade, not from import day" do
      described_class.call(user: user, rows: [ row ], dry_run: false)

      expect(Position.sole.opened_at.to_date).to eq(Date.new(2025, 12, 8))
    end

    it "moves the portfolio inception back so snapshots are not clamped away" do
      expect {
        described_class.call(user: user, rows: [ row ], dry_run: false)
      }.to change { portfolio.reload.inception_date }.from(Date.current).to(Date.new(2025, 12, 8))
    end

    it "stores FX against MXN even though the user prefers USD" do
      described_class.call(user: user, rows: [ row ], dry_run: false)

      expect(Trade.sole.fx_rate_at_execution).to eq(BigDecimal("18.2293"))
    end

    it "weights avg_cost across several buys of the same asset" do
      rows = [
        row(shares: "1.0", price_per_share: "100.0", external_id: "a", net_amount: nil),
        row(shares: "3.0", price_per_share: "200.0", external_id: "b", net_amount: nil)
      ]
      described_class.call(user: user, rows: rows, dry_run: false)

      expect(Position.sole.shares).to eq(4)
      expect(Position.sole.avg_cost).to eq(BigDecimal("175.0"))
    end

    it "publishes one batch event, not one per trade" do
      published = []
      EventBus.subscribe(Trading::Events::TradesImported, ->(event) { published << event })

      described_class.call(user: user, rows: [ row, row(external_id: "order-2") ], dry_run: false)

      expect(published.size).to eq(1)
      expect(published.first.trade_count).to eq(2)
      expect(published.first.earliest_executed_on).to eq("2025-12-08")
    end

    it "skips rows already imported instead of duplicating them" do
      described_class.call(user: user, rows: [ row ], dry_run: false)
      result = described_class.call(user: user, rows: [ row, row(external_id: "order-2") ], dry_run: false)

      expect(result.value![:imported]).to eq(1)
      expect(result.value![:skipped].first[:external_id]).to eq("order-1")
      expect(Trade.count).to eq(2)
    end

    it "replays out-of-order rows oldest first" do
      rows = [
        row(side: "sell", shares: "1.0", price_per_share: "150.0", executed_at: "2025-12-20T10:00:00-05:00", external_id: "s", net_amount: nil),
        row(shares: "4.0", price_per_share: "100.0", executed_at: "2025-12-08T10:00:00-05:00", external_id: "b", net_amount: nil)
      ]
      result = described_class.call(user: user, rows: rows, dry_run: false)

      expect(result).to be_success
      expect(Position.sole.shares).to eq(3)
    end
  end

  # EchoStar traded as SATS when the December statement printed and trades as
  # ECHO now. A file written then carries the old ticker forever.
  describe "a symbol the asset used to trade under" do
    let!(:echo) { create(:asset, symbol: "ECHO", currency: "USD", former_symbols: [ "SATS" ]) }

    it "resolves the row and books it against the live asset" do
      result = described_class.call(user: user, rows: [ row(asset_symbol: "SATS") ], dry_run: false)

      expect(result).to be_success
      expect(Trade.last.asset).to eq(echo)
    end

    it "does not resolve a symbol nobody claims, current or former" do
      result = described_class.call(user: user, rows: [ row(asset_symbol: "NOPE") ], dry_run: true)

      expect(result.failure).to eq([ :unknown_symbols, [ "NOPE" ] ])
    end

    # The two features were specced apart and never together, so the partial
    # import silently discarded a row the alias could have resolved -- losing
    # trades is exactly what the all-or-nothing refusal exists to prevent.
    it "keeps an aliased symbol when the rest of the file is being skipped" do
      rows = [ row(asset_symbol: "SATS"), row(asset_symbol: "NOPE", external_id: "x-2") ]

      result = described_class.call(user: user, rows: rows, dry_run: false, skip_unknown: true)

      expect(result.value![:imported]).to eq(1)
      expect(result.value![:dropped]).to eq({ "NOPE" => 1 })
      expect(Trade.last.asset).to eq(echo)
    end

    # Retired tickers get reassigned. If a live SATS ever existed, a purchase of
    # it landing in EchoStar's position would be money in the wrong instrument,
    # and nothing would say so.
    it "gives a live ticker to its own asset, never to the one that used to hold it" do
      live = create(:asset, symbol: "SATS", currency: "USD")

      described_class.call(user: user, rows: [ row(asset_symbol: "SATS") ], dry_run: false)

      expect(Trade.last.asset).to eq(live)
      expect(Trade.last.asset).not_to eq(echo)
    end
  end
end
