# Bulk trade import — design and defect audit

**Status:** proposal · **Date:** 2026-08-28

**Trigger:** 13 Alpaca/Bitso confirmation PDFs holding 50 real buys (2025-12-08 → 2025-12-26,
$510 USD, 25 symbols) with no way into the app. The portfolio has 0 trades today. Bitso's
public API is crypto-only — the equity product is Alpaca's Broker API, which is B2B — so the
confirmations are the only channel these movements have.

## 1. Decision: the app imports CSV, not PDF

The PDF stays outside. A parser lives in personal tooling and emits the CSV the app accepts.

**Why not parse PDFs in Rails:** it buys a permanent dependency and a permanent liability —
the layout is Alpaca's to change, and it only ever serves one broker. CSV serves the same
backfill plus manual bulk entry, a future Bitso crypto export, and any other broker, for a
fraction of the surface. The confirmations are already parsed and reconciled: $510.00 computed
against $510.00 from the broker's net amounts, 50 of 50 rows.

**The contract** is the seven fields `ExecuteTradeContract` already accepts, plus one:

```
asset_symbol, side, shares, price_per_share, fee, currency, executed_at, external_id
```

`external_id` is the broker's order id, and §3.5 is why it is not optional.

## 2. Decision: unknown symbols resolve in a preview step, they do not auto-create

The question this document exists to answer. Three options:

| Option | Verdict |
|---|---|
| Reject rows with unknown symbols | Rejected. 17 of 25 symbols are unknown today — a "successful" import of 33 rows of 50 is worse than none, because the portfolio is then silently wrong |
| Auto-create the asset from the CSV row | Rejected. The row carries a symbol and nothing else, so it creates `Asset(symbol: "AAPL", name: "AAPL")` with no type, exchange or country — and a typo becomes a junk asset that syncs forever |
| **Resolve in a preview step, commit after** | **Chosen** |

**The flow:** parse and validate everything, write nothing → report totals, rejected rows with
reasons, and every unknown symbol with `SearchTicker` results attached → the operator confirms,
corrects, or drops each → commit creates assets and trades together.

This is cheaper than it reads. `Administration::UseCases::Assets::SearchTicker` already resolves
a symbol to name / asset_type / exchange / country through Yahoo, and `Assets::CreateAsset`
already persists one with logo and sync status. The preview wires two existing use cases
together; it does not invent a resolver.

The preview is also where every other failure surfaces at once rather than one exception at a
time — the difference between a smart CSV and a CSV that stops on row 34.

## 3. Defects a bulk import hits today

Verified against the code and the live database, not inferred.

### 3.1 Backdated positions open today — `execute_trade.rb:66`

`create_new_position` sets `opened_at: Time.current`. Every imported position claims it was
opened on import day, so holding periods are wrong from the first row.

**Fix:** derive `opened_at` from the earliest `executed_at` in the position.

### 3.2 Eight months of history silently discarded — `rebuild_snapshots.rb:22`

The most serious one. `bounded_range` clamps the rebuild to the portfolio's inception:

```ruby
first = [ from, portfolio.inception_date ].compact.max
```

The live portfolio has `inception_date = 2026-08-22`. The trades start `2025-12-08`. Every
snapshot before August is dropped — no error, no warning, a history chart that begins eight
months after the money went in.

**Fix:** the import moves `inception_date` back to its earliest trade date. A data fix, not a
change to `RebuildSnapshots` — the clamp is correct for its own purpose.

### 3.3 Snapshot rebuild storms — `rebuild_snapshots_on_backdated_trade.rb`

The handler is `async? = true` and fires per trade, rebuilding from that trade's date to today.
Fifty backdated trades enqueue fifty jobs; the earliest spans ~263 days. That is on the order of
13,000 snapshot writes to produce ~263 rows, with the jobs racing on the `(portfolio_id, date)`
unique index.

**Fix:** one rebuild from the earliest imported date, after the transaction commits. See §4 for
how, because the obvious way is a flag and the flag is the wrong answer.

### 3.4 Imported trades are born uneditable — `trade.rb:26`, `delete_trade.rb:4`

`MODIFICATION_WINDOW` and `MAX_DELETE_AGE_DAYS` are both 30 days from `executed_at`. December
trades are already outside it, so a mistyped row cannot be fixed or removed through the UI —
only from a console.

The window is right for manual entry, where it guards against rewriting settled history, and
wrong for import, where the mistake is minutes old even though the trade is not.

**Decided 2026-08-28:** no batch-id column, no exemption from the window. Three cheaper pieces
cover it — the task is dry-run by default, `external_id` (§3.5) makes a re-run safe by
construction, and a companion `stockerly:undo_import[path]` reads the same CSV, discards those
trades by `external_id`, and recalculates the touched positions and rebuilds snapshots once.

That is an undo without a migration, and it does the recalculation a console `destroy_all`
would silently skip. The window keeps protecting what it was written to protect.

### 3.5 No idempotency — `trades` schema

There is no external reference on `trades`. Re-running an import duplicates every row, and two
of the thirteen PDFs are byte-identical re-downloads of confirmations already present — so
duplicate input is the normal case, not the edge case.

**Fix:** `external_id`, populated from the broker order id, with a partial unique index scoped
to the portfolio (`WHERE external_id IS NOT NULL`, so manually entered trades do not collide on
NULL). Rows whose id already exists are reported as skipped, not re-imported.

### 3.6 FX is captured relative to a setting that can change — `fx_rate_resolver.rb:33`

`fx_rate_at_execution` stores the rate expressing the trade currency in the user's **preferred
currency at the time of capture**. Preferred is `USD` today, so all 50 imported trades will
store `1.0`.

Switch preferred to MXN later and every one of them is wrong — and
`fx_rate_backfill:trades` will not repair them, because it only fills rows where the column
`IS NULL` and these are not null, they are `1.0`. The damage is silent and lands on cost basis.

**Decided 2026-08-28:** the import records the trade-currency→MXN rate always, regardless of the
current preference. The app is self-hosted and Mexico-first; MXN is the stable reference, the
preference is not.

This costs nothing today. `Position#avg_cost_in` short-circuits when the target matches the
asset's currency, so with `preferred = USD` and USD-denominated assets the stored rate is never
read — and the day the preference flips to MXN it is already correct, with no backfill.

Residual, pre-existing and out of scope: an MXN-denominated asset valued in USD would read the
rate in the wrong direction. The import does not create this and none of the 25 symbols hit it.

### 3.7 Silent share truncation — `trades.shares` is `precision: 15, scale: 6`

The broker reports nine decimals (`0.036232711`); the column holds six. It reconciles to the
cent across all 50 rows here, so it is not a blocker — but it is a silent rounding on
fractional-share buys, which are the only kind this import will ever carry.

**Fix:** no schema change. Assert it — compare the computed total against the row's net amount
and refuse the batch on a mismatch over one cent. A rounding you check is fine; one you assume
is how a portfolio drifts.

### 3.8 Order matters

Trades must be replayed oldest-first: `find_or_create_position` merges by asset, and a sell
ahead of its buy fails `sell_exceeds_position?`. The importer sorts rather than trusting the
file.

## 4. The real design tension: reuse `ExecuteTrade`, or not

Calling `ExecuteTrade` fifty times gets contract validation, position merging and avg-cost
recalculation for free. It also fires 150 event handlers, produces §3.3, and tempts a
`skip_events:` flag — a flag that exists only so a use case can lie about what it is.

The alternative is an importer that owns the batch: validate every row with the same contract,
insert trades, then recalculate each touched position once and rebuild snapshots once, and
publish a single `TradesImported` event rather than fifty `TradeExecuted`.

The second is correct. An import is not fifty executions — it is one replay with different
invariants, and modeling it as the first is what generates every symptom in §3.3. The cost is
that position-merge and avg-cost logic must be shared with `ExecuteTrade` rather than
duplicated; both already delegate to `Position#recalculate_avg_cost!`, so the shared surface is
small.

## 5. Panel

**C1 Lucía Ramírez — Mexican financial domain.** §3.6 is hers. *"The number shown to the user
must be true. `fx_rate_at_execution = 1.0` is true only while preferred is USD — you are
storing a user setting inside a trade and calling it history. Decide now, while there are zero
trades to repair."* Her invariant: after import, cost basis in MXN must be derivable without
knowing what the preference was on import day.

**C2 Hiroto Watanabe — DDD.** Owns §4. *"Don't put a flag on `ExecuteTrade` to make it stop
being itself. The import is a different use case with different invariants — one event, not
fifty."* Also: the importer lives in Trading, and it must create assets by calling
`Administration::UseCases::Assets::CreateAsset`, never `Asset.create!` — the public use case is
the boundary, direct model access is the leak.

**C3 Sven Kowalski — Rails 8.** *"`CreateAsset` publishes `AssetCreated` inside your
transaction. Roll back and you have fired events for assets that do not exist."* Collect the
events and publish after commit. On the migration: partial unique index, nullable column, no
backfill needed.

**C6 Esther Mwangi — scope.** The pushback that changed the plan. *"What has to be true for the
UI to be worth building now? That you import often enough for a rake task to hurt. You import
monthly, and you have never run this once. Phase 0 passes the 4-filter. Phase 1 does not — it
is a screen for a frequency you have not demonstrated."* Verdict: **later**, revisited after the
rake task has actually been used a few times.

**S6 Kenji Aragaki — migrations.** *"The table is empty. This is the cheapest moment this column
will ever have — add it now, not after 50 rows exist."* Rollback is a plain `remove_column`.

**S8 Mehmet Karadeniz — QA.** Fixture-driven use-case specs, negatives first: unknown symbol,
duplicate `external_id`, sell before buy, malformed date, total mismatching net amount, and one
real fixture cut from the actual 50 rows. No system spec — there is no UI to drive.

## 6. Phasing (revised after C6)

**Phase 0 — `stockerly:import_trades[path]`.** No UI. Unknown symbols abort with the full list,
so resolving them stays a deliberate step. Covers §3.1–3.3, §3.5, §3.7, §3.8, and the §4 batch
design. This is what puts the 50 real trades in the database, and what makes any later phase
testable against real data.

**Phase 1 — the preview/resolve/commit UI of §2.** Deferred, not scheduled. Revisit once the
rake task has been run enough times to show the friction is real.

Phase 0 is not throwaway: if Phase 1 ever lands, its commit step calls the same importer.

## 7. Decisions and what is still open

Resolved 2026-08-28:

1. **§3.6 FX semantics** — always record the trade-currency→MXN rate. Self-hosted and
   Mexico-first; MXN is the stable reference and the preference is not.
2. **§3.4 undo** — dry-run by default plus `stockerly:undo_import[path]`. No batch-id column,
   no exemption from the modification window.
3. **The 8 catalogue-grade symbols** (`VT VWO VGT AVGO AMD INTC NFLX COIN`) — in scope here,
   added to `AssetCatalog` alongside Phase 0.

Still open:

4. **Three asset lists** (`AssetCatalog`, `stockerly:seed_assets`, `db/seeds.rb`) have already
   drifted, and adding the 8 symbols means editing at least two of them. The import does not
   depend on collapsing them, but it adds a fourth way an asset gets created. Worth its own
   decision before the count grows.
