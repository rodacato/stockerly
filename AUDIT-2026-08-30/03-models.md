# Audit 03 — Persistence layer (app/models, db/schema.rb, db/migrate)

**Scope:** 38 files in `app/models/` (37 models + `ApplicationRecord`; `app/models/concerns/` is empty), `db/schema.rb` (584 lines, 33 tables, version `2026_08_30_000000`), 106 migrations.
**Method:** every "nothing reads this" claim was verified by grepping `app/ lib/ config/ spec/` before being written down.

**Headline:** the model layer is *disciplined* in the places most Rails codebases rot — only three callbacks in the whole tree, none of them doing cross-aggregate work; eager loading is used consistently; the FX history layer (`FxRateHistory`, `ExecutionRate`) is genuinely well-built. The debt is elsewhere: a currency invariant that no layer enforces, an aggregate uniqueness rule that only exists in a `find_by`, a fat `Portfolio` that is simultaneously a Trading aggregate and a MarketData FX cache, and a schema carrying nine dead columns and seventeen redundant indexes.

---

### [MODEL-01] Nothing anywhere requires a trade's currency to match its asset's — and `avg_cost` is the unlabeled sum of the mix
- **Severity:** P0
- **Effort:** M
- **Where:** `app/models/position.rb:50-57`, `app/contexts/trading/contracts/execute_trade_contract.rb:13`, `app/contexts/trading/use_cases/execute_trade.rb:14`, `app/views/trades/new.html.erb:53`, `app/contexts/trading/use_cases/import_trades.rb:234`, `db/schema.rb:389` (`positions.avg_cost`, no currency column)
- **Evidence:**
  ```ruby
  # position.rb:50
  def recalculate_avg_cost!
    buy_trades   = trades.kept.where(side: :buy)
    total_shares = buy_trades.sum(:shares)
    weighted_cost = buy_trades.sum("shares * price_per_share")   # <- no currency term
    update!(avg_cost: weighted_cost / total_shares)
  end
  ```
  ```ruby
  # execute_trade_contract.rb:13 — the only constraint on currency
  optional(:currency).maybe(:string, included_in?: Asset::SUPPORTED_CURRENCIES)
  ```
  ```erb
  <%# trades/new.html.erb:53 — the select is pre-picked from the USER's preference, not the asset's %>
  <%= f.select :currency, Asset::SUPPORTED_CURRENCIES, { selected: @currency }, ... %>
  <%# trades_controller.rb:9 → @currency = current_user.preferred_currency %>
  ```
  ```ruby
  # import_trades.rb:234
  def currency_of(row) = row[:currency].presence || "USD"
  ```
- **Why it matters:** a user whose `preferred_currency` is `MXN` — the default the MX-first product expects — opens the trade sheet on AAPL (a USD asset) and the currency select is already on MXN. Nothing rejects it: not the contract, not `ExecuteTrade`, not a `Position`/`Trade` validation, not a DB check constraint. The trade is persisted with `currency: "MXN"`, and the `RecalculateAvgCostOnTrade` handler then sums MXN and USD `price_per_share` values into one `avg_cost`, a column with no currency of its own (`Position#currency` just delegates to the asset). That number is consumed as asset-currency everywhere downstream:
  - `Position#avg_cost_in(target)` short-circuits with `return avg_cost.to_d if target == asset&.currency` (`position.rb:34`) — the poison bypasses the entire historical-FX path;
  - `PositionBreakdown#from_asset` / `#from_fx` (`position_breakdown.rb:23,33`) subtract it from a USD price to compute the MXN-vs-asset split — the exact reading the product exists to produce (JTBD #1, ADR-009);
  - `app/views/market/_position_summary.html.erb:60` renders it as `format_currency_mx(position.avg_cost, currency: position.asset.currency)` — an MXN number labeled USD.

  The CSV path is worse, because it is silent: a BMV export without a `currency` column stamps every row `USD` regardless of the asset.
- **Recommendation:** make the invariant explicit at three levels, cheapest first. (1) `Trade`: `validate { errors.add(:currency, :mismatch) if asset && currency != asset.currency }` — this is a genuine aggregate invariant, not ceremony. (2) `ImportTrades#currency_of` defaults to `asset.currency`, never a literal `"USD"`. (3) The form select defaults to the held/selected asset's currency (the Stimulus controller already carries `heldCurrencyValue`). Then decide whether a foreign-currency trade is a legitimate case at all — if it is, `positions` needs an `avg_cost_currency` column and `recalculate_avg_cost!` must translate through `ExecutionRate.multiplier` like `avg_cost_in` already does.
  **Migration risk:** the validation needs no migration. Existing rows may already be mixed — before landing the validation, run a read-only reconciliation (`Trade.kept.joins(:asset).where("trades.currency <> assets.currency")`) and report; do not auto-rewrite historical `currency` values, since which of the two is wrong (the currency or the price) cannot be inferred from the data.

> **C1 Lucía Ramírez (MX financial domain):** Este es el bug que el pivot dijo que ya estaba cerrado. La captura de `fx_rate_at_execution` está impecable — el problema es aguas arriba: si `price_per_share` entra en pesos para un activo en dólares, ningún tipo de cambio histórico lo salva, porque el número ya perdió su unidad antes de tocar la conversión. Un `avg_cost` sin moneda solo es honesto mientras la moneda del trade sea inderivable-por-construcción de la del activo. Aquí no lo es: es un `<select>`.

---

### [MODEL-02] "One open position per asset" is enforced by a `find_by`, not by the database
- **Severity:** P1
- **Effort:** S
- **Where:** `db/schema.rb:402`, `app/contexts/trading/use_cases/execute_trade.rb:53`
- **Evidence:**
  ```ruby
  # schema.rb:402 — composite, NOT unique
  t.index ["portfolio_id", "asset_id", "status"], name: "index_positions_on_portfolio_id_and_asset_id_and_status"
  ```
  ```ruby
  # execute_trade.rb:53
  existing = portfolio.positions.find_by(asset: asset, status: :open)
  return existing if existing
  ```
- **Why it matters:** `find_by` silently returns the *first* of N. Two open positions for one asset can be created by a concurrent write, an interrupted `ImportTrades` re-run, or an `UpdateTrade`/`DeleteTrade` that reopens a position (`update_trade.rb:64` sets `status: :open, closed_at: nil`) while another already exists. Once duplicated, `Portfolio#invested_value` double-counts the shares and every downstream figure is wrong with no error anywhere. The one place this rule *is* deliberately relaxed — fixed-income lots (`always_new_lot?`, `execute_trade.rb:69`) — makes the constraint harder, not impossible.
- **Recommendation:** partial unique index excluding fixed-income lots, e.g. `add_index :positions, [:portfolio_id, :asset_id], unique: true, where: "status = 0 AND maturity_date IS NULL", algorithm: :concurrently`, plus a `Position` uniqueness validation with the same scope so the app returns a validation failure instead of a 500.
  **Migration risk:** index creation will *fail* if duplicates already exist — that is the point, but it means the migration needs a pre-flight query and a dedupe step. Reversible; no data loss if the dedupe is a manual merge rather than a `delete_all`.

> **S6 Kenji Aragaki (migrations):** Un índice único que se agrega a una tabla ya sucia aborta el deploy a la mitad. En Postgres 16: primero `SELECT portfolio_id, asset_id, count(*) ... HAVING count(*) > 1` en una tarea de solo lectura, se resuelve a mano (son pocas filas en una instancia de un usuario), y hasta entonces el índice — con `algorithm: :concurrently` y `disable_ddl_transaction!`. Reversible, sin backfill.

---

### [MODEL-03] The remaining-shares formula is copy-pasted three times and one copy forgot `.kept`
- **Severity:** P1
- **Effort:** S
- **Where:** `app/contexts/trading/use_cases/update_trade.rb:60` vs `app/contexts/trading/use_cases/delete_trade.rb:39` vs `app/models/portfolio.rb:70-72`
- **Evidence:**
  ```ruby
  # delete_trade.rb:39  (correct)
  remaining = position.trades.kept.where(side: :buy).sum(:shares) - position.trades.kept.where(side: :sell).sum(:shares)

  # update_trade.rb:60  (bug — no .kept)
  remaining = position.trades.where(side: :buy).sum(:shares) - position.trades.where(side: :sell).sum(:shares)
  ```
- **Why it matters:** `Trade` is soft-deleted (`discarded_at`), and `Trade.kept` exists precisely for this. `UpdateTrade` omits it, so editing any trade on a position that has ever had a trade deleted recomputes `shares` from the discarded rows too — the position silently regains shares that were deleted, or refuses to close. `Trade.buys` / `Trade.sells` scopes also exist (`trade.rb:15-16`) and all three call sites reimplement them inline with raw `where(side:)`.
- **Recommendation:** one method — `Position#recalculate_shares!` next to `recalculate_avg_cost!`, or better, a `Trading::Domain::PositionRebuild` object that owns both — and delete the three inline copies. Use `trades.kept.buys` / `trades.kept.sells`. No migration.

---

### [MODEL-04] `Portfolio` is a fat aggregate that is also the FX cache, and it reads MarketData's ActiveRecord directly
- **Severity:** P1
- **Effort:** L
- **Where:** `app/models/portfolio.rb:17-113` (114-line model, 11 public methods, 6 private)
- **Evidence:**
  ```ruby
  # portfolio.rb:87 and :95 — a Trading model reaching into MarketData tables
  fx_rate_cache[[from, to]] ||= FxRate.find_by(base_currency: from, quote_currency: to)&.rate
  FxRateHistory.rate_on(base: from, quote: to, date: date) || current_rate(from, to)
  ```
- **Why it matters:** three separate problems in one file.
  1. **Boundary.** CLAUDE.md / ADR-002 forbids Trading from touching MarketData's ActiveRecord models. `Portfolio` — a Trading aggregate — calls `FxRate.find_by` and `FxRateHistory.rate_on` directly. There is no `MarketData::Queries::FxRate*`, so the rule is unenforceable as written; the boundary exists in the doc and not in the code.
  2. **Domain logic in AR.** `invested_value`, `total_unrealized_gain`, `allocation_by_*`, `shares_held_on`, `position_market_value_in` are portfolio *calculations* living in the persistence class, while `app/contexts/trading/domain/` already holds `PortfolioSummary`, `PositionBreakdown`, `PeriodReturnsCalculator`, `TimeWeightedReturn` — all of which delegate back into the model. The 24-line explanatory comment block at `portfolio.rb:27-33` and `:58-68` is itself the signal: this code needed a design note that a domain object would have carried in its class name.
  3. **A cache with the lifetime of an AR instance.** `@fx_rate_cache` (`portfolio.rb:111`) is correct within one request and invisible across two — and it silently falls back to *today's* rate when history is missing (`portfolio.rb:95`), which is exactly the dishonesty ADR-009 was written to remove, applied at a layer where no caller can see it happened.
- **Recommendation:** extract the FX access into a `MarketData::Queries::ExchangeRate` (current + historical + explicit `Quote` with its `source`, which `FxRateHistory.quote_on` already returns) and inject it. Move `invested_value` / `total_unrealized_gain` / `allocation_by_asset_type` into `Trading::Domain::PortfolioSummary`, which already owns their callers. Leave `Portfolio` with associations, `open_positions`/`closed_positions`, and `shares_held_on`. No migration.

---

### [MODEL-05] `portfolio_snapshots.total_value` and `invested_value` always hold the same number
- **Severity:** P1
- **Effort:** S
- **Where:** `db/schema.rb:371,373`; `app/models/portfolio.rb:17-19`; `app/jobs/take_snapshots_job.rb:24-25`; `app/contexts/trading/use_cases/rebuild_snapshots.rb:33`
- **Evidence:**
  ```ruby
  # portfolio.rb:17
  def total_value(currency: user.preferred_currency)
    invested_value(currency: currency)          # literally delegates
  end

  # rebuild_snapshots.rb:33 — states it outright
  snapshot.update!(currency: currency, invested_value: invested, total_value: invested)
  ```
- **Why it matters:** two `decimal(15,2) null: false` columns, two model validations (`portfolio_snapshot.rb:5-6`), and two writers per snapshot for one fact. Worse, the two names promise different things — `total_value` reads as "including cash", `invested_value` as "cost of holdings" — so a future reader will assume a distinction that the code deleted (`20260824220000_remove_dead_cash_concept.rb` is where it went). Every consumer (`PortfolioSummary#total_value_of`, `TimeWeightedReturn:67`, `PeriodReturnsCalculator:67`, `AssembleConsolidado:97`) reads only `total_value`; nothing reads `invested_value` at all.
- **Recommendation:** drop `invested_value` and keep `total_value`, or collapse `Portfolio#total_value` into `invested_value` and drop the alias method. Both writers and the validation go with it.
  **Migration risk:** column drop is irreversible without a backup, but the data is a verbatim duplicate of a column that stays — no information is lost. Do it in two steps (ignore-column deploy, then drop) only if zero-downtime matters; on a single-user self-hosted box a straight `remove_column` is fine.

---

### [MODEL-06] `PortfolioSummary#to_h` reloads the open positions five times per render
- **Severity:** P1
- **Effort:** S
- **Where:** `app/contexts/trading/domain/portfolio_summary.rb:11-58`, `app/models/portfolio.rb:9-40,98-104`
- **Evidence:** nothing in `PortfolioSummary` is memoized, and `Portfolio#open_positions` returns a fresh relation each call (`positions.where(status: :open)`), so every `.includes(...).sum { }` re-executes.
  ```
  to_h →  total_value            → open_positions.includes(:asset).sum         (load 1)
       →  unrealized_gain        → total_unrealized_gain → includes(:asset,:trades) (load 2)
                                 → total_invested        → includes(:asset,:trades) (load 3)
       →  day_gain               → total_value (again)                          (load 4)
       →  total_invested (again)                                                (load 5)
  ```
- **Why it matters:** the dashboard, `/portfolio`, `/assets` and `/discover` all build a `PortfolioSummary` (`assemble_panorama.rb:43`, `assemble_consolidado.rb:73`, `load_assets.rb:44`). Five full loads of positions + assets + trades per page for a figure set that is deterministic within one request. The `@fx_rate_cache` in `Portfolio` survives (same AR instance), so this is pure SQL waste, not incorrectness — but it scales with trade count, which is the one number that only grows.
- **Recommendation:** memoize `total_value`, `total_invested`, `unrealized_gain`, `day_gain` in `PortfolioSummary` (`@x ||=`), and memoize the loaded position collection once in `Portfolio` (`@open_positions_loaded ||= open_positions.includes(:asset, :trades).to_a`) so all four figures iterate the same array. No migration.

> **S3 Yui Nakashima (performance):** Cinco cargas para un `to_h` es lo que se ve cuando un objeto de dominio delega a un modelo que devuelve una relación nueva en cada llamada. La corrección es de dos líneas y no toca SQL. Lo que sí vigilaría después: `Position#avg_cost_in` llama `ExecutionRate.multiplier` **por trade**, y ese método consulta `FxRateHistory` cuando la moneda objetivo no es ni la del trade ni MXN — con preferencia en USD y trades en pesos, eso es una query por trade de compra, dentro de un `sum` que ya está dentro de otro `sum`.

---

### [MODEL-07] `AlertRule` infers currency from a `.MX` string suffix and has no `asset_id` at all
- **Severity:** P1
- **Effort:** M
- **Where:** `app/models/alert_rule.rb:54-56`; `db/schema.rb:43,49` (`asset_symbol` string, `threshold_value` with no currency column)
- **Evidence:**
  ```ruby
  def currency
    asset_symbol.to_s.match?(/\.MX\z/i) ? "MXN" : "USD"
  end
  ```
- **Why it matters:** `assets.currency` is the authoritative column (`schema.rb:94`, `null: false`, validated against `Asset::SUPPORTED_CURRENCIES`), and this method ignores it in favour of a filename-style heuristic. Any MXN-denominated asset whose symbol lacks the suffix is labeled USD — which is precisely the fixed-income catalogue (`CETES_28D` and friends, `currency: "MXN"`, `face_value` in pesos per `_fixed_income_detail.html.erb:50`). A `price_crosses_below` rule on a CETE therefore renders its threshold with the wrong currency badge. Separately, `alert_rules` joins to assets by *string symbol* with no FK, so a symbol rename orphans every rule on that asset silently — and `assets.former_symbols` (`schema.rb:100`, with a GIN index) exists precisely because symbols do get renamed.
- **Recommendation:** `AlertRule#currency` should resolve through the asset (`Asset.find_by(symbol: asset_symbol)&.currency || "USD"`), or the rule should carry a nullable `asset_id` FK alongside `asset_symbol` for the market-wide conditions that legitimately have no asset. The FK is the honest fix and makes `Asset.high_priority`'s symbol subquery (`asset.rb:56`) an id subquery.
  **Migration risk:** adding a nullable `asset_id` + backfill by symbol is reversible and safe; rows whose symbol no longer matches an asset stay NULL and should be reported, not guessed.

---

### [MODEL-08] `trades.total_amount` truncates crypto precision, and goes stale on update by design
- **Severity:** P1
- **Effort:** S
- **Where:** `db/schema.rb:498,497,500`; `app/models/trade.rb:13,44-46`; `app/contexts/trading/use_cases/update_trade.rb:47`
- **Evidence:**
  ```ruby
  t.decimal "shares",          precision: 15, scale: 6     # schema.rb:498
  t.decimal "price_per_share", precision: 15, scale: 4     # schema.rb:497
  t.decimal "total_amount",    precision: 15, scale: 2, null: false   # schema.rb:500
  ```
  ```ruby
  before_validation :calculate_total_amount, on: :create   # trade.rb:13 — create ONLY
  ```
- **Why it matters:** two things. (1) `shares × price` can legitimately need 10 decimal places (0.00012345 BTC at 894.5231) and is stored at 2 — the derived total does not reconcile with its own operands, and `DividendPayment#total_amount` (`schema.rb:160`) and `portfolio_snapshots` (`371,373`) share the 2-scale while `positions.avg_cost` and `assets.current_price` use scale 4. Money columns in this schema use three different scales (2, 4, and 15,6 for shares) with no stated rule. (2) The callback is `on: :create`, so on update the column is only correct because `UpdateTrade` remembers to recompute it by hand (`update_trade.rb:47`). Any other writer — a rake task, a console fix, a future use case — leaves a stale total silently.
- **Recommendation:** either drop the `on: :create` so the callback maintains the invariant on every save, or delete the column and make `total_amount` a derived method (it has exactly two readers, both formatting). Given the project's "money is a plain decimal" stance, deriving is cleaner than storing a third denormalized copy. Separately, write down the scale rule: prices 15,4, quantities 15,6, aggregates 15,4 (not 2).
  **Migration risk:** widening `total_amount` to `15,4` is a safe in-place `ALTER TYPE` in Postgres (no rewrite for a scale increase within the same precision? — it *does* rewrite; on a single-user table this is milliseconds). Dropping it is irreversible but the value is fully recomputable from `shares × price_per_share`.

---

### [MODEL-09] Nine columns nothing reads — including one that was supposed to record consent
- **Severity:** P2
- **Effort:** M
- **Where:** `db/schema.rb:97, 105, 108, 112, 317, 392, 394, 528, 529`
- **Evidence:** grepped across `app/ lib/ config/ spec/`:

  | Column | schema.rb | Status |
  |---|---|---|
  | `assets.div_yield` | 97 | Only `db/seeds.rb` and the original `create_assets` migration. No reader, no writer. |
  | `assets.pe_ratio` | 108 | Zero writers, zero readers. The P/E the UI shows comes from `asset_fundamentals.metrics` jsonb (`_pe_chart.html.erb`, `MetricDefinitions`). |
  | `assets.shares_outstanding` | 112 | Zero writers, zero readers; the gateway hash key of the same name feeds the jsonb path. |
  | `assets.market_cap` | 105 | **Write-only.** `sync_single_asset_job.rb:65` / `sync_bulk_crypto_job.rb:42` write `data[:market_cap] \|\| asset.market_cap` — the only read is its own fallback. Displayed market cap comes from `FundamentalPresenter` reading the jsonb. |
  | `market_indices.is_open` | 317 | **Write-only.** `sync_market_indices_job.rb:41,54` write it; no view, query or helper reads it. |
  | `positions.labels` | 392 | Zero references outside the schema and migration. |
  | `positions.notes` | 394 | Zero references outside the schema and migration. |
  | `users.avatar_url` | 528 | Zero references outside the schema and the 2026-02 `create_users` migration. |
  | `users.consents_data_processing_at` | 529 | **Zero references** outside the schema and its own migration (`20260518161033`). |

- **Why it matters:** `users.consents_data_processing_at` is the one worth stopping on. It was added deliberately in May 2026 to timestamp LFPDPPP consent and *nothing ever writes it* — so the instance records no consent, and a reader of the schema would reasonably conclude it does. That is a compliance claim backed by an always-NULL column. The other eight are the ordinary cost: four of them (`market_cap`, `pe_ratio`, `shares_outstanding`, `div_yield`) are a duplicate storage strategy for data that now lives in `asset_fundamentals.metrics` — the migration to jsonb happened and the columns stayed.
- **Recommendation:** drop all nine. Do `consents_data_processing_at` as a separate decision: either wire it (the Setup Wizard is the obvious writer) or drop it and stop implying consent is tracked — do not leave it as-is.
  **Migration risk:** all irreversible-without-backup, none carries information. `assets.market_cap` and `market_indices.is_open` have live writers that must be removed in the same PR or the deploy raises `UnknownAttributeError`. Use the two-phase `ignored_columns` → drop pattern if any job may be mid-flight.

---

### [MODEL-10] Seventeen redundant indexes, and two FK columns with no index at all
- **Severity:** P2
- **Effort:** M
- **Where:** `db/schema.rb` throughout; the two gaps at `551` and `162`
- **Evidence — redundant** (a single-column index whose column is already the leading column of a composite on the same table; Postgres uses the composite for both):

  `assets.asset_type` (119, vs 118) · `assets.country` (121, vs 120) · `alert_events.user_id` (29, vs 28) · `alert_rules.user_id` (55, vs 54) · `asset_fundamentals.asset_id` (67, vs 66) · `asset_price_histories.asset_id` (86, vs 85) · `dividends.asset_id` (174, vs 173) · `earnings_events.asset_id` (188, vs 187) · `financial_statements.asset_id` (240, vs 239) · `market_index_histories.market_index_id` (310, vs 309) · `otp_recovery_codes.user_id` (364, vs 363) · `positions.portfolio_id` (403, vs 402) · `stock_splits.asset_id` (447, vs 446) · `system_logs.severity` (462, vs 461) · `technical_observations.asset_id` (473, vs 472) · `trades.portfolio_id` (508, vs 505/506) · `trend_scores.asset_id` (523, vs 522).

  **Evidence — missing:**
  ```ruby
  # schema.rb:551 — watchlist_items has ONLY the composite led by user_id …
  t.index ["user_id", "asset_id"], name: "index_watchlist_items_on_user_id_and_asset_id", unique: true
  add_foreign_key "watchlist_items", "assets"        # …but the FK points at asset_id

  # schema.rb:162 — dividend_payments, same shape
  t.index ["portfolio_id", "dividend_id"], name: "...", unique: true
  add_foreign_key "dividend_payments", "dividends"   # dividend_id unindexed
  ```
- **Why it matters:** the redundant seventeen cost write amplification on every insert into the hottest tables in the app (`asset_price_histories`, `trend_scores`, `technical_observations` — the ones a sync job writes in bulk) and buy nothing on read. The two missing ones are the classic Postgres FK trap: Postgres does *not* index the referencing side, so every `Asset#destroy` (which cascades `watchlist_items`) and every `Dividend#destroy` (cascading `dividend_payments`) does a sequential scan, and so does `DividendPayment` → `dividend` in `AssembleHistorial`'s `includes(dividend: :asset)`.
- **Recommendation:** drop the seventeen, add `index :watchlist_items, :asset_id` and `index :dividend_payments, :dividend_id`. Note that `assets` in a single-user instance holds tens of rows and carries **nine** indexes — that table in particular should be trimmed to `symbol` (unique) plus the GIN on `former_symbols`.
  **Migration risk:** `remove_index` is reversible and metadata-only; do it `algorithm: :concurrently` out of habit even though the tables are small. Zero data risk.

> **S3 Yui Nakashima:** Diecisiete índices que Postgres nunca elige, en una instancia de un solo usuario donde ninguna tabla justifica un plan complejo. El costo no es el disco, es que cada `INSERT` de `SyncBulkStocksJob` mantiene índices que nadie lee. Y el par que falta es el que sí duele: un FK sin índice en el lado referenciante convierte cualquier `DELETE` del padre en un seq scan — silencioso hasta que la tabla crece.

---

### [MODEL-11] Nine model methods and scopes whose only callers are their own specs
- **Severity:** P2
- **Effort:** S
- **Where:** verified by grepping `app/ lib/` excluding `app/models/`
- **Evidence:**

  | API | Defined | Only referenced from |
  |---|---|---|
  | `Position#total_gain`, `#total_gain_percent` | `position.rb:17,21` | `spec/contexts/trading/domain/multi_currency_audit_spec.rb:85-90` |
  | `Portfolio#allocation_by_sector` | `portfolio.rb:42` | `spec/models/portfolio_allocation_spec.rb`, `spec/integration/multi_currency_portfolio_spec.rb:77` |
  | `Asset#price_stale?` | `asset.rb:71` | `spec/models/asset_spec.rb:216` |
  | `Asset#last_sync_ok?` | `asset.rb:75` | nothing at all — not even a spec |
  | `FxRate.convert`, `.last_refresh` | `fx_rate.rb:11,17` | `spec/models/fx_rate_spec.rb:48,61` |
  | `MarketIndex.major` | `market_index.rb:12` | `spec/models/market_index_spec.rb:27` |
  | `AuditLog.by_user` | `audit_log.rb:9` | `spec/models/audit_log_spec.rb:36` |

- **Why it matters:** `Position#total_gain` and `#total_gain_percent` are the currency-blind versions of exactly the calculation `PositionBreakdown` was built to replace — they subtract `avg_cost` from `current_price` with no FX term at all. Leaving them public is an invitation for the next feature to call the wrong one, and their spec (`multi_currency_audit_spec.rb`) actively documents them as correct-but-native. `MarketIndex.major` is a leftover of the `/market` listing deleted in the 2.0 cleanup (D31); `AuditLog.by_user(user_id)` is single-user ceremony (see MODEL-13). A test that exists only to keep a method alive is coverage theater, not a safety net.
- **Recommendation:** delete the method and its spec together. Where a caller might plausibly return (`Portfolio#allocation_by_sector` for a future sector donut), that is a reason to keep the *test data*, not the dead method. No migration.

---

### [MODEL-12] `notifications` stores read-ness twice
- **Severity:** P2
- **Effort:** S
- **Where:** `db/schema.rb:347,348`; `app/models/notification.rb:24,25,41-43`; `app/contexts/notifications/use_cases/mark_as_read.rb:12`
- **Evidence:**
  ```ruby
  t.boolean  "read",    default: false, null: false   # schema.rb:347
  t.datetime "read_at"                                # schema.rb:348
  ```
  Every writer sets both (`notification.rb:42`, `mark_as_read.rb:12`); every reader uses only `read` (`unread`, `read_only`, `by_estado`).
- **Why it matters:** two columns, one fact, and an index on `[user_id, read]` (`schema.rb:354`) that pins the redundant one. The two can diverge on any partial write — a row with `read: true, read_at: nil` is representable and means nothing.
- **Recommendation:** drop `read`, keep `read_at`, and redefine the scopes as `where(read_at: nil)` / `where.not(read_at: nil)`; move the index to `[user_id, read_at]`. `read_at` is strictly more informative and cannot disagree with itself.
  **Migration risk:** backfill needed before the drop (`UPDATE notifications SET read_at = updated_at WHERE read = true AND read_at IS NULL`), then drop the column and swap the index. Reversible only if the backfill is done first — do them as two migrations, not one.

---

### [MODEL-13] Single-user leftovers: a role enum with one possible value, and per-user scoping ceremony throughout
- **Severity:** P2
- **Effort:** M
- **Where:** `db/schema.rb:539,542`; `app/models/user.rb:9,34`; `app/models/asset.rb:12`; `app/models/audit_log.rb:9`
- **Evidence:**
  ```ruby
  enum :role, { user: 0, admin: 1 }        # user.rb:9
  scope :admins, -> { where(role: :admin) } # user.rb:34 — never called in app/
  t.index ["role"], name: "index_users_on_role"   # schema.rb:542 — index on a one-row table
  has_many :watching_users, through: :watchlist_items, source: :user   # asset.rb:12 — plural of one
  ```
  The only account is created by `Identity::UseCases::CreateFirstAdmin` with `role: :admin` (`create_first_admin.rb:23`), and `SetupController#require_no_users` blocks a second. `require_admin` (`admin/base_controller.rb:7`) therefore always passes.
- **Why it matters:** ten tables carry a `user_id` FK that can only ever hold one value (`alert_rules`, `alert_events`, `notifications`, `watchlist_items`, `audit_logs`, `push_subscriptions`, `otp_recovery_codes`, `alert_preferences`, `portfolios`, `site_config_changes.admin_id`). That is not itself wrong — ripping them out is a large, risky, low-reward migration and ADR-0010 chose "pivot in place". What *is* worth fixing is the ceremony built on top: an `admins` scope nothing calls, an index on a column with one row and one value, an `admin?` guard that cannot fail, a `watching_users` association whose plural is a lie, and `AuditLog.by_user(user_id)` as a filter over a table with one user.
- **Recommendation:** keep the `user_id` columns (cheap, harmless, and they document the aggregate root). Delete the surface: `User.admins`, `index_users_on_role`, `Asset#watching_users`, `AuditLog.by_user`. Leave `role` itself — `profiles/_identity_card.html.erb:8` renders it and it costs nothing.
  **Migration risk:** dropping one index, metadata-only, reversible.

---

### [MODEL-14] Validations and the schema disagree in six places
- **Severity:** P2
- **Effort:** M
- **Where:** as listed
- **Evidence:**

  | Disagreement | Where |
  |---|---|
  | `site_configs.value` is `default: "", null: false` but the model has `validates :value, presence: true` — the schema's own default is invalid per the model, so `SiteConfig.set(key, "")` raises. | `schema.rb:435` vs `site_config.rb:3` |
  | Unique index with **no** model uniqueness validation → `RecordNotUnique` (a 500) instead of a validation failure: `asset_fundamentals` `(asset_id, period_label)`, `dividend_payments` `(portfolio_id, dividend_id)`, `trades` `(portfolio_id, external_id)`. | `schema.rb:66,162,507` |
  | Models with **zero** validations while the DB has `null: false` columns: `AlertPreference` (whole model is 3 lines), `OtpRecoveryCode` (`code_digest null: false`, no presence validation) → `NotNullViolation` instead of `errors`. | `alert_preference.rb`, `otp_recovery_code.rb:1-9` vs `schema.rb:358` |
  | `trades.currency` is `null: false, default: "USD"` with **no** model-level inclusion validation — only the contract constrains it, so any non-contract writer (rake, console, a future importer) can persist anything. | `schema.rb:489` vs `trade.rb` |
  | `financial_statements.currency` is nullable *with* a `"USD"` default and no validation — a money-bearing jsonb (`data`) whose unit can be NULL. | `schema.rb:229-230` |
  | `fear_greed_readings` has a **non-unique** index on `(index_type, fetched_at)` and no uniqueness validation, so the same poll can be stored twice; `FearGreedReading.latest_crypto` would then be arbitrary among ties. | `schema.rb:223` |

- **Why it matters:** each one turns a user-visible validation error into a 500, or lets a bad value through a side door. None is urgent alone; together they mean "the model validates it" is not a safe assumption anywhere in this codebase, which makes the ones that *do* matter (MODEL-01) harder to argue for.
- **Recommendation:** fix `site_configs` first (drop the `presence` validation — the empty default is the intentional one). Add uniqueness validations mirroring the three unique indexes. Add `validates :currency, inclusion: { in: Asset::SUPPORTED_CURRENCIES }` to `Trade` alongside the MODEL-01 match check. Leave `AlertPreference` — it is a settings row created by a handler with all four booleans defaulted; a validation there would be ceremony.
  **Migration risk:** none — all app-side.

---

### [MODEL-15] FX precision differs between where a rate is stored and where it is captured
- **Severity:** P2
- **Effort:** S
- **Where:** `db/schema.rb:247, 260, 494`
- **Evidence:**
  ```ruby
  t.decimal "rate", precision: 15, scale: 6                  # fx_rate_histories (247)
  t.decimal "rate", precision: 15, scale: 6                  # fx_rates (260)
  t.decimal "fx_rate_at_execution", precision: 15, scale: 8  # trades (494)
  ```
- **Why it matters:** `ExecutionRate.capture` reads `FxRateHistory.rate_on` (6 decimals) and writes it into an 8-decimal column, so two of the eight are always zero — the extra precision is real only for the user-supplied `override` path and for the `stored / divisor` division inside `multiplier`, which is computed, not stored. Harmless today, but it means a reader cannot tell from the schema which of the two scales is the project's actual FX precision. `MXN/USD` at 6 decimals is ~0.0001 centavos on a 1,000,000 MXN position — fine; the point is that the schema should say so once.
- **Recommendation:** pick one — 8 everywhere (widen the two `rate` columns) or 6 everywhere (narrow `fx_rate_at_execution`) — and record it. Widening is the safer direction.
  **Migration risk:** widening scale within the same precision is a table rewrite in Postgres but reversible and lossless. **Narrowing would round existing values** — do not narrow.

> **C1 Lucía Ramírez:** Banxico publica el FIX a cuatro decimales. Seis ya es más precisión de la que el emisor da; ocho es ruido con apariencia de exactitud. Si se va a unificar, que sea hacia seis y que quede escrito de dónde viene el número — un tipo de cambio con ocho decimales invita a que alguien crea que se puede reconciliar contra el estado de cuenta al centavo, y no se puede.

---

### [MODEL-16] Two `scope :recent` bake a `LIMIT` into their name
- **Severity:** P2
- **Effort:** S
- **Where:** `app/models/alert_event.rb:11`, `app/models/fear_greed_reading.rb:22`
- **Evidence:**
  ```ruby
  scope :recent, -> { order(triggered_at: :desc).limit(10) }        # alert_event.rb:11
  scope :recent, -> { order(fetched_at: :desc).limit(30) }          # fear_greed_reading.rb:22
  ```
  Nine other models define `scope :recent` as ordering only (`Trade`, `Notification`, `AuditLog`, `SystemLog`, `ErrorEvent`, `StockSplit`, `PortfolioSnapshot`, `DividendPayment`, `MarketIndexHistory`, `TechnicalObservation`, `FinancialStatement`).
- **Why it matters:** `.recent` means "ordered newest first" everywhere in this codebase except two places, where it also silently truncates. `CurrentFearGreed` (`current_fear_greed.rb:15`) already has to write `FearGreedReading.crypto.recent.reorder(fetched_at: :asc)` — a `reorder` to undo half of what the scope did, on a relation still capped at 30 by the other half. A composed `.recent.where(...)` on either model returns the wrong set, and nothing warns.
- **Recommendation:** rename to `last_10` / `last_30`, or strip the `limit` and let callers state it. No migration.

---

## What is healthy (so the report is not only a list of defects)

- **Callbacks.** Three in 37 models: `Trade#calculate_total_amount`, `User#downcase_email`, `WatchlistItem#capture_entry_price`. None publishes an event, none writes another aggregate, none is conditional on another callback. This is the anti-pattern the audit was told to look hardest for, and it is genuinely absent — the side effects go through `EventBus` (`config/initializers/event_subscriptions.rb`, 40 subscriptions) as the architecture says they should. The one nit is `WatchlistItem#capture_entry_price` reading `asset.current_price` (a Trading model reading MarketData state) — the same boundary as MODEL-04, at 1/50th the size.
- **`FxRateHistory` / `ExecutionRate`.** The best code in the layer. `quote_on` returns a `Data` carrying the rate *and* the date it is really for *and* its source, walks back to the last available auction, inverts the pair when only the reverse exists, and `record_all` upserts against the unique index instead of two queries per row. `ExecutionRate`'s `REFERENCE = "MXN"` decision — anchoring to a fixed currency rather than the user's preference — is exactly right and the comment explaining why is worth its lines.
- **Uniqueness.** 17 of the 33 tables carry a real unique index, and most are mirrored by a model validation. The exceptions are listed in MODEL-14 and MODEL-02.
- **Eager loading.** `AssembleHistorial`, `AssembleConsolidado`, `PortfolioSummary#total_invested`, `TakeSnapshotsJob`, `LoadAssetPosition` all `includes` correctly. The N+1s that remain (MODEL-06, and the per-trade FX lookup Yui flags) are repetition and inner-loop lookups, not missing preloads.
- **Migrations.** 106 of them, and a striking number are *deletions* — `drop_email_events`, `drop_user_activities`, `drop_invite_codes`, `drop_remember_tokens`, `remove_multi_user_columns_from_users`, `remove_dead_cash_concept`, `remove_change_percent_24h_from_assets`, `drop_portfolio_insights_table`. The 2.0 subtraction was real and it reached the schema. MODEL-09 is what that sweep missed, not evidence that it did not happen.

---

## Ranked summary

| ID | Severity | Effort | Title |
|---|---|---|---|
| MODEL-01 | P0 | M | Trade currency is not constrained to the asset's; `avg_cost` sums the mix |
| MODEL-02 | P1 | S | One-open-position-per-asset enforced by `find_by`, not by an index |
| MODEL-03 | P1 | S | Remaining-shares formula copied 3×; `UpdateTrade` copy omits `.kept` |
| MODEL-04 | P1 | L | `Portfolio` is fat, is the FX cache, and reads MarketData AR directly |
| MODEL-05 | P1 | S | `portfolio_snapshots.total_value` == `invested_value`, always |
| MODEL-06 | P1 | S | `PortfolioSummary#to_h` reloads open positions five times |
| MODEL-07 | P1 | M | `AlertRule#currency` from a `.MX` suffix; no `asset_id` FK |
| MODEL-08 | P1 | S | `trades.total_amount` scale 2 vs shares 6; callback is `on: :create` only |
| MODEL-09 | P2 | M | Nine dead columns, including an always-NULL consent timestamp |
| MODEL-10 | P2 | M | 17 redundant indexes; 2 FK columns unindexed |
| MODEL-11 | P2 | S | Nine model APIs alive only for their own specs |
| MODEL-12 | P2 | S | `notifications.read` + `read_at` store one fact twice |
| MODEL-13 | P2 | M | Single-user leftovers: `admins` scope, role index, `watching_users` |
| MODEL-14 | P2 | M | Six validation/schema disagreements |
| MODEL-15 | P2 | S | FX scale 6 in the rate tables, 8 in `trades` |
| MODEL-16 | P2 | S | Two `scope :recent` with a baked-in `LIMIT` |

**Suggested order:** MODEL-01 first and alone (it is a correctness bug in the product's differentiator and its fix needs a data reconciliation before the validation lands). Then MODEL-03 and MODEL-02 together — both are position-integrity, both are small. MODEL-05/06/09/10/12 are a single low-risk cleanup PR. MODEL-04 is the only L and should wait for a decision on whether `MarketData::Queries::ExchangeRate` is worth introducing.
