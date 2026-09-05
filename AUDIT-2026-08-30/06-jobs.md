# Audit 06 — Background job layer

**Scope:** `app/jobs/` (37 job classes + 3 concerns = 40 files), `config/recurring.yml`,
`config/queue.yml`, `config/initializers/data_sources.rb`, `config/initializers/event_subscriptions.rb`.
**Method:** read every file; cross-checked every job class against `app/`, `lib/`, `config/`, `db/`
with grep to prove who enqueues it; cross-checked every `task_name` string written by a job against
the strings `CheckSyncHealthJob` reads.
**Date:** 2026-08-30. Branch `fix/capture-daily-volume`. Read-only — nothing was modified or enqueued.

---

## Verdict

The job layer is **structurally sound and operationally broken.** The shape is right — 14 of 37 jobs
are genuinely thin adapters that call a use case and log; `PausableSync`, `SyncLogging` and the
`GatewayChain`/`DataSourceRegistry` seams are real abstractions that earn their place. What is wrong
is that the layer has drifted out of alignment with itself: a scheduled job crashes on every run
because it writes a column that does not exist, the observability job monitors three strings that
its producers never write, the cheap bulk path for US stocks is orphaned while the expensive
per-asset path runs every five minutes, and the seeded ETF catalogue is never priced at all.

None of this is visible from a green test suite, because the specs fabricate the strings the jobs
are supposed to agree on instead of letting the producer write and the consumer read.

**Distribution:** 3 × P0, 11 × P1, 5 × P2.

---

# P0

### [JOB-01] `SyncFxHistoryJob` raises on every single run — the Banxico FIX sync has never logged
- **Severity:** P0
- **Effort:** S (<1h)
- **Where:** `app/jobs/sync_fx_history_job.rb:29`, against `db/schema.rb:450-463`
- **Evidence:**
  ```ruby
  # sync_fx_history_job.rb:24-32
  def log(severity, message, started)
    SystemLog.create!(
      task_name: "FX History Sync",
      module_name: "sync",
      severity: severity,
      message: message,              # <-- system_logs has no `message` column
      duration_seconds: (Time.current - started).round(2)
    )
  end
  ```
  `system_logs` columns are `created_at, duration_seconds, error_message, log_uid, module_name,
  severity, task_name, updated_at`. `SystemLog` (`app/models/system_log.rb`, 11 lines) defines no
  `message` accessor. `SystemLogging#log_sync_success` correctly uses `error_message:`; this job
  hand-rolls its own logger and got the keyword wrong.
- **Why it matters:** `ActiveRecord::UnknownAttributeError` on **both** branches, success and
  failure. Every nightly 19:00 run ends in an unhandled exception. The use case at line 12 runs
  first, so `FxRateHistory` *is* written — then the job dies. Consequences: (a) zero `SystemLog`
  rows for "FX History Sync" have ever existed, so Registros shows the historical-FX sync as if it
  never ran; (b) the job is permanently red in Mission Control; (c) `CheckSyncHealthJob` does not
  monitor this task name either, so nothing tells the owner. This is the job that feeds the
  historical FX series behind ADR-009's honest gain — the exact thing the project calls first-class.
  There is **no spec** for this job (`spec/jobs/` has 37 files; `sync_fx_history_job_spec.rb` is not
  among them), which is why it shipped.
- **Recommendation:** delete the private `log` method and `include SyncLogging` like the other 20
  sync jobs; `log_sync_success("FX History Sync", message: "...")` / `log_sync_failure`. Add
  `"FX History Sync"` to `CheckSyncHealthJob::CRITICAL_SYNCS`. Add the missing spec, and assert on
  the persisted `SystemLog` row rather than on a stubbed logger.

---

### [JOB-02] `CheckSyncHealthJob` monitors three task names its producers never write — permanent false alerts, permanent blind spots
- **Severity:** P0
- **Effort:** M (1-4h)
- **Where:** `app/jobs/check_sync_health_job.rb:48-57` and `:69`; producers at
  `app/jobs/sync_bulk_crypto_job.rb:19`, `app/jobs/sync_bulk_bmv_job.rb:43`,
  `app/jobs/sync_bulk_stocks_job.rb:10`
- **Evidence:**
  ```ruby
  # check_sync_health_job.rb:69-75 — the cure lookup is an exact match
  last_success = logs.where(severity: :success).order(created_at: :desc).first
  ...
  return if last_success.present?   # recent success cures prior errors

  # sync_bulk_crypto_job.rb:19 — the success row's task_name carries the count
  log_sync_success("Bulk Crypto Sync: #{assets.size} assets")
  # sync_bulk_bmv_job.rb:43
  log_sync_success("Bulk BMV Sync: #{quotes.size} assets")
  ```
  The failure paths (`sync_bulk_crypto_job.rb:21,23`, `sync_bulk_bmv_job.rb:27,29`) log the bare
  `"Bulk Crypto Sync"` / `"Bulk BMV Sync"`. So for the two bulk syncs that actually run, the error
  rows match `CRITICAL_SYNCS` and the success rows **never** do.
- **Why it matters:** three distinct failures in one job.
  1. **False-positive alert loop.** One transient CoinGecko or DataBursatil error creates a
     `"Bulk Crypto Sync"` error row. No success row can ever cure it, because successes are filed
     under a different string. `CheckSyncHealthJob` then fires an owner notification —
     *"Tus criptomonedas no se han actualizado en más de un día"* — which is false, and re-fires
     every 6 hours (`DEDUP_TTL`) for the next 25 hours. The one job whose entire purpose is turning
     silent failure into a notice the owner receives is a notification spammer that cries wolf.
  2. **`"Bulk Stock Sync"` is monitored but unreachable.** `SyncBulkStocksJob` is the only writer of
     that string and **nothing in `app/`, `lib/`, `config/` enqueues it** (see JOB-04). US equity
     staleness — the largest slice of the portfolio — has no health check at all. The header comment
     at `check_sync_health_job.rb:18` asserts "every 5-30 min via SyncPriorityAssetsJob", which is
     factually wrong.
  3. **A dead worker is undetectable by design.** `:73` returns early when there are no error rows.
     If Solid Queue dies, or `auto_sync_enabled` is switched off, or a job is dropped from
     `recurring.yml`, there are neither successes nor errors — and the sweep says nothing. On a
     self-hosted box "the worker is dead" is the single most likely failure, and it is the one this
     job cannot see.
  The spec (`spec/jobs/check_sync_health_job_spec.rb:34,94-95`) hand-builds `SystemLog` rows with
  the exact literals the job expects, so it validates the consumer against itself and can never
  catch a producer/consumer mismatch.
- **Recommendation:** (a) make `task_name` a stable identifier — move every per-run count into the
  `message:`/`error_message:` payload where it belongs, and promote `TASK_NAME` constants (as
  `SyncBulkStocksJob:10` already does) that both the producer and `CRITICAL_SYNCS` reference, so a
  rename cannot silently break the pairing; (b) add a **liveness** arm — for each monitored task,
  alert when the newest row of *any* severity is older than its expected cadence × 2, which is what
  catches a dead worker; (c) rewrite the spec to drive the real producer jobs and then assert the
  sweep stays quiet, instead of fabricating log rows.

> **S1 Olusegun Adebayo (DevOps/observability):** "This is monitoring that reports on itself. The
> alerting contract is a bare string typed in two files that no test compares, and the one condition
> a single-box deploy actually suffers — the worker process being gone — is explicitly returned
> early on. Constants and a heartbeat, and it becomes a real check."

---

### [JOB-03] ETFs are never price-synced — 9 seeded ETFs get one price at creation and then freeze
- **Severity:** P0
- **Effort:** S (<1h)
- **Where:** `config/recurring.yml:13-26`; `app/jobs/sync_priority_assets_job.rb:12`;
  catalogue at `app/contexts/administration/domain/asset_catalog.rb:44-55`
- **Evidence:** the only recurring price entries are
  ```yaml
  sync_high_priority_stocks: args: [ "stock", "high" ]   # every 5 minutes
  sync_low_priority_stocks:  args: [ "stock", "low"  ]   # every 30 minutes
  sync_all_crypto:           args: [ "crypto", "all" ]   # every 5 minutes
  ```
  and the job filters hard: `scope = Asset.syncing.where(asset_type: asset_type)`. `Asset`'s enum
  (`app/models/asset.rb:4`) is `{ stock: 0, crypto: 1, index: 2, etf: 3, fixed_income: 4 }`. Nothing
  else enqueues by type — grep for `SyncPriorityAssetsJob|SyncSingleAssetJob` across `app/ lib/
  config/` returns only `LaunchInitialSync` (which also hardcodes `"stock"` and `"crypto"`) and
  `SyncAssetOnCreation`. The seeded catalogue ships SPY, QQQ, VOO, VTI, ARKK, VT, VWO, VGT and
  IVVPESO.MX as `asset_type: "etf"`.
- **Why it matters:** an owner who holds VOO — the single most likely holding for this persona —
  sees the price captured at asset creation and never again. `price_updated_at` stops advancing, so
  `Asset#price_stale?` is permanently true, portfolio value is wrong by however much the ETF has
  moved since, and every derived figure (snapshots, gain, allocation, trend scores) inherits the
  error. It is silent: no error is logged because no sync is attempted. `SyncAllAssetsJob` — the one
  job that accepts a nil `asset_type` and would have covered every type — is dead code (JOB-04).
- **Recommendation:** widen the scope rather than adding a fourth cron line — `asset_type` should
  accept an array, and the schedule should read `args: [ ["stock","etf"], "high" ]`. Also decide
  explicitly what `index` and `fixed_income` assets do here: CETES are refreshed by `SyncCetesJob`,
  so `fixed_income` is deliberately excluded — write that down in the job, because right now the
  exclusion is indistinguishable from the ETF bug.

---

# P1

### [JOB-04] The bulk US-stock path is dead code; the expensive per-asset path runs every 5 minutes
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/sync_bulk_stocks_job.rb` (whole file), `app/jobs/sync_all_assets_job.rb`
  (whole file), `app/jobs/sync_priority_assets_job.rb:40-44`
- **Evidence:** grep across `app/ lib/ config/ db/ bin/` for `SyncBulkStocksJob` returns **only** its
  own definition, `check_sync_health_job.rb:18` (a comment), and two spec files. Same for
  `SyncAllAssetsJob`: the only non-spec hit outside its own file is a comment in
  `app/shared/domain/data_source_registry.rb:12` using it as a docstring example. Meanwhile the live
  path is:
  ```ruby
  # sync_priority_assets_job.rb:42-44
  us_assets.find_each.with_index do |asset, index|
    SyncSingleAssetJob.set(wait: index * 12).perform_later(asset.id)
  end
  ```
  Crypto and BMV both got their bulk jobs wired (`:29`, `:37`). US stocks did not.
- **Why it matters:** two costs. **Provider quota:** N assets = N HTTP calls every 5 minutes during
  market hours, where `SyncBulkStocksJob` would spend exactly 1 (`AlpacaGateway#fetch_bulk_prices`).
  With 20 US holdings that is ~1,560 calls per market day instead of ~78. **Queue saturation:** at
  12s spacing, 25+ US assets take longer than 300s to drain, so the next cron tick starts enqueuing
  before the previous batch finishes. `SyncSingleAssetJob#recently_synced?` (`:46-51`) throws the
  duplicates away *after* they have already occupied one of the three worker threads. The
  `spacing_seconds` heuristic in the dead `SyncAllAssetsJob` (`:22-29`) is the third copy of the
  same rate-limit reasoning.
- **Recommendation:** wire `SyncBulkStocksJob.perform_later(us_assets.pluck(:id))` into
  `sync_equities`, mirroring the BMV branch exactly — this also repairs JOB-02's `"Bulk Stock Sync"`
  monitor for free. Keep `SyncSingleAssetJob` for the single-asset paths that genuinely need it
  (`SyncAssetOnCreation`, manual refresh). **Delete `SyncAllAssetsJob`** — it is superseded by
  `SyncPriorityAssetsJob`, has no caller, and its existence is what makes JOB-03 look covered.

> **S2 Adriana Cienfuegos (gateways, rate limits):** "You built the bulk endpoint, tested it, and
> then never plugged it in — so the provider sees twenty conversations where one would do. Alpaca
> tolerates it; the point is that the fallback chain and the circuit breaker are now being exercised
> twenty times per tick instead of once, which is twenty chances to trip a breaker on a bad minute."

---

### [JOB-05] Three sync jobs swallow every gateway failure and then log success
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/sync_splits_job.rb:15` + `:38`; `app/jobs/sync_dividends_job.rb:16` + `:30`;
  `app/jobs/sync_index_history_job.rb:22` + `:40`
- **Evidence:**
  ```ruby
  # sync_splits_job.rb:13-38
  assets_with_open_positions.each do |asset|
    result = chain_for(asset).fetch_splits(asset.gateway_symbols)
    next if result.failure?          # <-- no log, no counter, no re-raise
    ...
  end
  log_sync_success("Splits Sync", message: "#{detected} new splits detected")
  ```
  `sync_dividends_job.rb:16` and `sync_index_history_job.rb:22` are the identical shape.
- **Why it matters:** a total provider outage is indistinguishable from "nothing changed". All three
  jobs report `severity: :success` with a count of zero. This is not a cosmetic logging issue — it
  is the input `CheckSyncHealthJob` reads, so a permanently broken dividends or splits feed can
  never raise an alert, by construction. Splits are the worst case: a missed 4:1 split leaves the
  position's `shares` and `avg_cost` wrong until someone notices by eye, and there is no second pass
  that would catch it. Dividends are the same shape one level down.
- **Recommendation:** count failures alongside successes and choose the severity from the ratio —
  all-failed is `:error`, some-failed is `:warning`, none-failed is `:success` — the way
  `SyncBulkBmvJob#report` (`:39-59`) already does correctly. That method is the pattern the other
  three should copy; it is the best error-reporting code in the job layer.

---

### [JOB-06] `retry_on Faraday::Error` is dead configuration; the errors that *do* escape get no retry at all
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/sync_single_asset_job.rb:11`, `sync_bulk_bmv_job.rb:11`,
  `sync_bulk_crypto_job.rb:9`, `sync_bulk_stocks_job.rb:12`; `app/jobs/application_job.rb:1-7`
- **Evidence:** every gateway already converts Faraday exceptions into monadic failures before
  returning — `rescue Faraday::Error => e` appears in `alpaca_gateway.rb:189`,
  `coingecko_gateway.rb:71,95,119`, `data_bursatil_gateway.rb:158`, `finnhub_gateway.rb` (×6),
  `banxico_gateway.rb:50,76,115`, `alpha_vantage_gateway.rb` (×3), `fmp_gateway.rb` (×3),
  `fx_rates_gateway.rb:28`, `crypto_fear_greed_gateway.rb:20`. A `Faraday::Error` cannot reach the
  job. Meanwhile `ApplicationJob` is an empty shell — both its `retry_on` and `discard_on` lines are
  commented out:
  ```ruby
  # application_job.rb:2-6
  # retry_on ActiveRecord::Deadlocked
  # discard_on ActiveJob::DeserializationError
  ```
- **Why it matters:** the retry policy is inverted. The exception class that is declared retryable
  never occurs; the ones that actually occur — `ActiveRecord::Deadlocked`, `RecordInvalid`,
  `PG::ConnectionBad`, `NoMethodError` on a shape-shifted provider payload — have no `retry_on`
  anywhere, so ActiveJob lets them fail permanently on the first try. A one-second database blip at
  23:00 loses the entire nightly snapshot run until tomorrow. And `ActiveJob::DeserializationError`
  is not discarded, so a `BackfillPriceHistoryJob` for an asset the owner deleted stays failed in
  Mission Control forever, as noise on the screen meant to show real failures.
- **Recommendation:** move the policy up to `ApplicationJob` where it belongs:
  `retry_on ActiveRecord::Deadlocked, ActiveRecord::ConnectionNotEstablished, wait: :polynomially_longer, attempts: 3`
  and `discard_on ActiveJob::DeserializationError`. Delete the four per-job `retry_on Faraday::Error`
  lines, or keep exactly one with a comment explaining which gateway is expected to let Faraday
  escape — right now they read as protection that does not exist.

---

### [JOB-07] `SplitAdjuster` is not idempotent and has no transaction — one Mission Control retry doubles the portfolio
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/contexts/trading/domain/split_adjuster.rb:12-40`, reached from
  `app/jobs/sync_splits_job.rb:28-33` → `Trading::Handlers::AdjustPositionsOnSplit` (async) →
  `app/jobs/process_event_job.rb:4-7`
- **Evidence:**
  ```ruby
  def adjust!
    positions = Position.where(asset: @split.asset)
    positions.find_each do |position|
      position.with_lock { position.update!(shares: position.shares * @ratio, avg_cost: position.avg_cost / @ratio) }
    end
    adjust_trades!            # <-- outside any transaction
  end
  ```
  There is no marker recording that this split was already applied, and no wrapping transaction.
- **Why it matters:** two ways to corrupt cost basis. (a) **Re-run.** `ProcessEventJob` has no
  `retry_on`, so a failure here parks a red job at `/admin/jobs` (Mission Control) with a retry
  button. Pressing it re-multiplies every position by the ratio — a 4:1 split becomes 16:1 and the
  avg cost is quartered twice. Nothing detects it; the numbers stay plausible. (b) **Partial
  failure.** If `adjust_trades!` raises on trade #7 of 30, positions are already adjusted and seven
  trades are adjusted while 23 are not. There is no rollback, and re-running compounds (a) on top.
  `SyncSplitsJob` itself is safe — `next unless split.new_record?` at `:19` prevents a re-publish —
  so the exposure is exclusively through job retry, which is the one path the operator is invited to
  use.
- **Recommendation:** wrap `adjust!` in a single `ActiveRecord::Base.transaction`, and add an
  applied-marker (a `applied_at` timestamp on `stock_splits`, or a `split_id` stamp on the adjusted
  rows) checked at the top so a second call is a no-op. Given the DDD conventions, `adjust!` is
  business logic that already lives correctly in `Domain::` — this is a fix in place, not a move.

---

### [JOB-08] `SyncDividendsJob`: payments are created only on a dividend's first insert, so a crash mid-loop loses them permanently
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/sync_dividends_job.rb:64-95`
- **Evidence:**
  ```ruby
  next unless dividend.new_record? || dividend.changed?
  dividend.save!
  create_payments(dividend) if dividend.previously_new_record?
  ```
- **Why it matters:** `create_payments` iterates portfolios and can raise (or the worker can be
  killed) after `dividend.save!` has committed. On the next weekly run the dividend row exists and is
  unchanged, so `next` fires and `create_payments` is never called again. The `DividendPayment` is
  lost forever with no error surfaced — the money simply never appears in Historial. The
  `find_or_create_by!` at `:85` means re-running is safe; the problem is that re-running never
  happens.
  Secondary, and squarely in the project's first-class concern: `total_amount` at `:90` is
  `shares * dividend.amount_per_share` in the **dividend's** currency (`:61`, defaulting to `"USD"`),
  but `dividend_payments` (`db/schema.rb:155-163`) has **no currency column**. A BMV dividend in MXN
  and a US dividend in USD land in the same untagged decimal. `AssembleHistorial` (`:22`) lists them
  together; the moment anything sums that list, it adds MXN to USD — the exact class of bug ADR-0010
  and the multi-currency P0 work were about.
- **Recommendation:** (a) make payment creation independent of insertion — reconcile every dividend
  in the window against its expected payments each run, rather than keying off
  `previously_new_record?`; the unique index on `(portfolio_id, dividend_id)` already makes that
  safe. (b) Add `currency` to `dividend_payments`, copied from the dividend, before anything
  aggregates it. (c) Move the whole `sync_dividends_for` / `create_payments` body into a
  `MarketData::UseCases::SyncDividends` — 70 of this job's 103 lines are entitlement rules
  (`RECENTLY_CLOSED`, ex-date share reconstruction, payment derivation), which is domain logic, not
  adapter code.

---

### [JOB-09] `SyncStatementsJob` breaks mid-asset on a rate limit, and the orchestrator then excludes that asset for a week
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/sync_statements_job.rb:24-46`; `app/jobs/sync_all_statements_job.rb:40-43`
- **Evidence:**
  ```ruby
  # sync_statements_job.rb:35
  break if result.failure[0] == :rate_limited

  # sync_all_statements_job.rb:40-43 — next week's eligibility
  .where("id NOT IN (SELECT DISTINCT asset_id FROM financial_statements WHERE fetched_at > ?)", 7.days.ago)
  ```
- **Why it matters:** the three statement types are fetched in sequence. If Alpha Vantage's 25/day
  free tier is exhausted after the income statement, the job breaks with 1 of 3 persisted — and
  because *a* `financial_statements` row now has a fresh `fetched_at`, next Sunday's orchestrator
  excludes the asset entirely. The balance sheet and cash flow are never fetched. Worse, the job
  still publishes `FinancialStatementsSynced` at `:41` (guarded only by `synced_types.empty?`), so
  `RecalculateFundamentalsOnStatementsSynced` recomputes ratios from an income statement with no
  balance sheet behind it. That is a wrong number displayed confidently, which is the failure mode
  the project cares most about.
- **Recommendation:** make the unit of work atomic per asset — either all three statements persist
  or none do (buffer, then write in one transaction), and only publish the event on a complete set.
  Change the orchestrator's exclusion from "any statement fetched recently" to "all three statement
  types fetched recently", so a partial asset is retried first rather than skipped.

---

### [JOB-10] Two different valuation engines write `portfolio_snapshots` for the same date
- **Severity:** P1
- **Effort:** L (>4h)
- **Where:** `app/jobs/take_snapshots_job.rb:18-29` vs
  `app/contexts/trading/use_cases/rebuild_snapshots.rb:31-35` +
  `app/contexts/trading/domain/historical_valuation.rb:15-40`
- **Evidence:** the nightly job values positions live —
  `Portfolio#position_market_value_in` (`app/models/portfolio.rb:106-109`) uses
  `position.asset.current_price` and **today's** FX rate. `RebuildSnapshots` values the same day from
  `HistoricalValuation#invested_on(date)`, which reads the `AssetPriceHistory` close for that date
  and the historical FX. `RebuildSnapshots#bounded_range` (`:21-27`) caps at `Date.current`
  **inclusive**, so a backdated trade recorded today rewrites today's snapshot too.
- **Why it matters:** the same row can hold two different numbers depending on which writer touched
  it last, and the difference is real — live price with today's FX vs the day's official close with
  the day's FX. The performance chart, `TimeWeightedReturn` (`:67`) and `PeriodReturnsCalculator`
  (`:67`) all read `snapshot.total_value` and cannot tell which engine produced it. A single
  backdated trade silently re-bases the whole visible history onto a different methodology.
  (Related but *not* a bug: `Portfolio#total_value` is literally `invested_value` (`portfolio.rb:17-19`),
  and `RebuildSnapshots:33` writes the same value to both columns deliberately. That is consistent —
  but `TakeSnapshotsJob:24-25` calls both methods, so it computes the identical figure twice, paying
  the full position-load and FX-conversion cost a second time for nothing.)
- **Recommendation:** one writer, one engine. `HistoricalValuation` is the better one (it is
  date-honest and ADR-009-consistent), so `TakeSnapshotsJob` should call
  `Trading::UseCases::RebuildSnapshots.call(portfolio:, from: Date.current)` and stop having a
  valuation opinion of its own. That collapses the job to ~8 lines, removes the duplicate
  computation, and makes the snapshot table single-sourced.

> **S3 Yui Nakashima (performance):** "`Portfolio.includes(:user, :positions, positions: :asset)` at
> `take_snapshots_job.rb:7` is decorative — `invested_value` calls `open_positions.includes(:asset)`,
> which builds a fresh relation and discards everything you preloaded. You pay for the eager load and
> then query again, twice, because the job calls two methods that are the same method. At one
> portfolio it costs milliseconds; it is worth fixing because it teaches the wrong pattern to the
> next person who copies this job."

---

### [JOB-11] `ResolveTrackedSymbolsJob` re-enqueues itself forever when the provider is persistently throttled
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `app/jobs/resolve_tracked_symbols_job.rb:12-36`
- **Evidence:**
  ```ruby
  remaining = drain(pending.dup, user, added, unresolved)
  return self.class.set(wait: RETRY_IN).perform_later(remaining, user_id, added, unresolved) if remaining.any?
  ```
  `drain` re-queues the current symbol and breaks on `:throttled` (`:29-32`). There is no attempt
  counter and no deadline.
- **Why it matters:** if the ticker provider is down, misconfigured, or rate-limits everything (the
  gateway path is a `PythonRunner` subprocess with a per-call cap), `resolve` returns `:throttled`
  every time, `remaining` never shrinks, and the job re-enqueues itself every 60 seconds
  indefinitely. On a single-worker box with 3 threads that is a permanent occupant, and the owner
  never gets the notification at `:56` because the job never reaches it. The failure is completely
  silent — no `SystemLog`, no `SyncLogging` include at all.
- **Recommendation:** thread an attempt count through the arguments (or use
  `executions`, which ActiveJob provides free), cap it at ~10 passes, and on exhaustion send the
  notification with whatever was resolved plus an honest "these could not be checked" line. Failing
  silently forever is the worst of the three possible outcomes.

---

### [JOB-12] `BackfillPriceHistoryJob` silently drops the rest of the year on the first bad bar — and logs success
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `app/jobs/backfill_price_history_job.rb:84-105`, with `:19`
- **Evidence:**
  ```ruby
  def upsert_bars(asset, bars, source)
    bars.each do |bar|
      ... record.save!
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Ignore race conditions on concurrent upserts
  end
  ```
  The `rescue` is at **method** scope, not inside the `each`.
- **Why it matters:** the comment says "ignore race conditions on concurrent upserts", which is what
  it would do if the rescue were inside the loop. As written, one invalid bar at index 10 aborts
  bars 10–364 and returns normally — then line 19 logs `"Backfill: SYMBOL"` as a **success**. The
  asset ends up with 10 days of history presented as a completed 365-day backfill.
  `BackfillMissingHistoriesJob` uses `< 200 histories` as its eligibility test
  (`backfill_missing_histories_job.rb:31`), so a 10-row asset does get retried weekly — and hits the
  same bad bar, and truncates at the same place, forever. Every downstream consumer of
  `PriceSeries` (trend scores, technical observations, `HistoricalValuation`) reads a series that
  ends where the exception was.
- **Recommendation:** move the `rescue` inside the `bars.each` block so a bad bar skips one bar, and
  count the skips. If any bar was skipped, log `:warning` with the count instead of `:success`.

---

### [JOB-13] `CalculateTrendScoresJob` inlines a verbatim copy of a handler's logic, and the two writers overlap
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/calculate_trend_scores_job.rb:9-25` vs
  `app/contexts/market_data/handlers/recalculate_trend_score_on_price_update.rb:12-25`
- **Evidence:** the two bodies are line-for-line identical — same `PriceSeries.latest(WINDOW)`, same
  `pluck(:close).map(&:to_f)`, same `closed_volumes`, same `TrendScoreCalculator.calculate`, same
  `trend_scores.create!` with the same five attributes. The job wraps it in
  `Asset.syncing.find_each`; the handler wraps it in a `find_by(id:)`.
- **Why it matters:** this is the clearest DDD violation in the layer — business logic living in a
  job with a duplicate living in a handler, so a change to the scoring contract has to be made twice
  or it silently diverges. Operationally the two also collide: `RecalculateTrendScoreOnPriceUpdate`
  is `async? = true` and fires on **every** `AssetPriceUpdated`, so a high-priority stock already
  writes a `TrendScore` row every 5 minutes; the nightly job at 23:30 then writes one more for every
  syncing asset. `PruneTrendScoresJob` exists solely to clean up after this volume
  (`prune_trend_scores_job.rb:1-2` says so explicitly). The nightly job's only unique contribution
  is scoring assets whose price did **not** change that day.
- **Recommendation:** extract one `MarketData::UseCases::CalculateTrendScore.call(asset:)` (or a
  `Domain::` service) and have both the job and the handler call it. Then reconsider whether the
  nightly sweep is needed at all: if it is, narrow it to assets with no `TrendScore` from today,
  which is the only gap the handler leaves — and most of `PruneTrendScoresJob`'s work disappears
  with it.

---

### [JOB-14] `SyncIntegrationJob` leaves an integration stuck in `syncing` if the process dies mid-probe
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `app/jobs/sync_integration_job.rb:19-33`
- **Evidence:**
  ```ruby
  integration.update!(connection_status: :syncing)
  result = test_connectivity(integration)      # network call, can hang or the worker can be killed
  ```
  There is no `ensure`, no timeout guard, no reconciliation elsewhere — grep shows nothing resets a
  stale `syncing`.
- **Why it matters:** `syncing` is a transient state written before a network call with no writer on
  the crash path. A deploy, an OOM kill, or a `PythonRunner` hang during the probe leaves
  `/admin/integrations` showing "sincronizando" permanently. The owner's only recovery is to trigger
  the sync again and hope, and there is nothing on the screen saying the state is stale.
- **Recommendation:** wrap the probe in `begin/ensure` so the status always resolves to `connected`
  or `disconnected`, and treat "still `syncing` and `updated_at` older than a few minutes" as
  `disconnected` when rendering.

---

# P2

### [JOB-15] One queue, three threads, no priorities — a 365-day backfill shares a lane with alert evaluation
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `config/queue.yml:1-8`; all 37 jobs declare `queue_as :default`; `config/recurring.yml`
  sets no `priority:` on any entry
- **Evidence:** `workers: [{ queues: "*", threads: 3, processes: ENV.fetch("JOB_CONCURRENCY", 1) }]`.
  Every job — `ProcessEventJob` (alert evaluation, trend recalcs, split adjustment),
  `BackfillPriceHistoryJob` (365 bars per asset, up to 50 assets on Sunday at 03:00),
  `ResolveTrackedSymbolsJob` (a Python subprocess per symbol), `WarmDiscoverJob` — shares the same
  three threads.
- **Why it matters:** `SyncMarketIndicesJob` and `SyncIndexHistoryJob` route through
  `YfinanceGateway`, which shells out via `PythonRunner` (`yfinance_gateway.rb:149`). A subprocess
  that runs to its timeout holds one of three threads for its whole duration. Two of those at once
  and a third of the pool is gone; a Sunday-3am backfill batch plus an in-flight yfinance call can
  leave alert evaluation waiting behind them. It has not bitten yet because the volume is one user's
  — this is the finding that becomes real the first time the box is under any load.
- **Recommendation:** three queues — `latency` (`ProcessEventJob`, notifications, broadcasts),
  `sync` (the recurring gateway jobs), `bulk` (backfills, symbol resolution, statements) — and give
  `latency` its own worker entry. It is a config change plus a `queue_as` line per job.

---

### [JOB-16] `AdaptiveScheduling` is a write-only abstraction — nothing ever reads the multiplier
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `app/jobs/concerns/adaptive_scheduling.rb:22-49`; callers at
  `sync_single_asset_job.rb:23,25` and `sync_market_indices_job.rb:24,26`
- **Evidence:** grep for `adaptive_multiplier` across `app/ lib/ config/` returns exactly two hits:
  its own definition (`:43`) and its usage example in the concern's own header comment (`:20`). No
  scheduler, job or gateway reads it.
- **Why it matters:** 50 lines of documented backoff machinery that computes a 1/2/4 multiplier,
  writes it to Solid Cache with a 24h TTL, and is never consulted. Two jobs pay a cache write per
  run for it. It reads as working rate-limit protection to anyone auditing the layer — which is
  worse than having none, because it is the answer someone will give when asked "how do we handle
  throttling?".
- **Recommendation:** either finish it (have `SyncPriorityAssetsJob` read
  `adaptive_multiplier` and scale the `wait:` spacing, which is the obvious consumer) or delete the
  concern and its two includes. Half-built is the one state that should not survive the audit.

---

### [JOB-17] Sync cadence is provisioned for a trading desk, not a weekly single user
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `config/recurring.yml:13-26`, `:71-77`
- **Evidence:** stocks every 5 min, crypto every 5 min (24/7 — crypto never checks market hours),
  market indices every 10 min, news every 30 min.
- **Why it matters:** `docs/vision/` and the project memory describe a user who opens the app
  **weekly**. Crypto at 5-minute resolution is 288 CoinGecko calls/day; indices at 10 minutes is 144
  yfinance subprocesses/day (each holding a worker thread — see JOB-15) of which the majority run
  outside market hours and do nothing but the `close_indices` UPDATE at
  `sync_market_indices_job.rb:41`. The cost is not money, it is that every one of these is a chance
  to trip a circuit breaker or generate a spurious error row that JOB-02's broken health check will
  then alert on.
- **Recommendation:** 15 minutes for high-priority equities, 15 for crypto, 30 for indices during
  market hours only, 2 hours for news. Nothing on this screen is read at 5-minute resolution by a
  weekly visitor.

---

### [JOB-18] `SyncIndexHistoryJob` reports rows it did not create
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `app/jobs/sync_index_history_job.rb:27-34`
- **Evidence:** `synced += 1` runs after `find_or_create_by!`, which increments for rows that
  already existed. The job fetches `days: 5` daily, so 4 of every 5 counted rows are pre-existing.
- **Why it matters:** the daily log reads `"~15 records synced"` when the true number of new rows is
  ~3. Minor on its own; it matters because `SystemLog` messages are the only operational narrative
  the owner has, and a number that is 5× reality trains them to ignore it.
- **Recommendation:** count only when the block ran — capture the record and check
  `previously_new_record?`.

---

### [JOB-19] `SyncCetesHistoryJob`'s keyword defaults make a manual re-run ambiguous
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `app/jobs/sync_cetes_history_job.rb:7`
- **Evidence:** `def perform(term: "28", from: nil, to: Date.current)` — the recurring entry passes
  no args, so `from: nil` is what production always uses; what window the use case then picks is
  invisible from the job. Compare `SyncFxHistoryJob:8-12`, which names `LOOKBACK_DAYS = 7`
  explicitly for exactly this reason.
- **Why it matters:** the schedule at `recurring.yml:109-111` runs weekly, so a missed run leaves a
  gap and nothing here says whether the next run heals it. `SyncFxHistoryJob`'s comment ("it asks
  for a week back … so a missed run or a holiday gap heals itself") documents the invariant that
  this job leaves implicit.
- **Recommendation:** give it an explicit `LOOKBACK` default so the healing window is stated where
  the schedule is read.

---

## Duplication map — the sync_* family (20 jobs)

The 20 `sync_*` jobs are **not** twenty copies of one thing. They fall into four shapes, and only
one of them is genuinely duplicated.

**Shape A — thin use-case adapters (6 jobs, ~15 lines each). Correct. Do not touch.**
`SyncCetesJob`, `SyncCetesHistoryJob`, `SyncEarningsJob`, `SyncNewsJob`, plus the non-sync
`DetectTechnicalObservationsJob`, `NotifyEarningsJob`, `NotifyMaturitiesJob`, `SendDailyDigestJob`.
Every one is `result = UseCase.call` → `log_sync_success` / `log_sync_failure`. This is exactly what
CLAUDE.md asks a job to be. `SyncFxHistoryJob` belongs in this group and is the outlier that
hand-rolled its logger — which is how JOB-01 happened.

**Shape B — bulk price fetch + upsert + publish (3 jobs). Real duplication, ~85% identical.**
`SyncBulkStocksJob` (71 lines), `SyncBulkCryptoJob` (61), `SyncBulkBmvJob` (95). All three:
resolve assets → `index_by` a symbol → `breaker.call { gateway.fetch_bulk_prices(keys) }` →
branch on `success` / `rate_limited|circuit_open` / else → `update_assets` looping
`old_price` → `asset.update!` → `price_changed?` → publish `AssetPriceUpdated`. `price_changed?` is
byte-identical in all three (`sync_bulk_stocks_job.rb:68-70`, `sync_bulk_crypto_job.rb:58-60`,
`sync_bulk_bmv_job.rb:92-94`), and `update_assets` differs only in which optional field it carries
(`volume` vs `market_cap`) and the default `source`.
**Safe to merge?** Yes — into one `MarketData::UseCases::UpdatePricesFromBulkQuote` that all three
jobs call, keeping the three job classes as thin per-provider adapters. Keep them separate as
classes: they have different circuit-breaker keys (`alpaca` / `crypto` / `databursatil`), different
symbol resolution (`symbol` vs `symbol_for(PROVIDER)`), and different `task_name`s that the health
check reads. Collapsing them into one parameterised job would make JOB-02 harder to fix, not easier.
`SyncBulkBmvJob#report` (`:39-59`) is the only one that reports partial results honestly and must
survive the merge — it is the behaviour the other two should gain, not lose.

**Shape C — orchestrators that enqueue per-asset work (5 jobs). Mostly justified.**
`SyncPriorityAssetsJob`, `SyncAllAssetsJob` (dead — delete, JOB-04), `SyncAllFundamentalsJob`,
`SyncAllStatementsJob`, `BackfillMissingHistoriesJob`. Each repeats a `each_with_index` +
`set(wait: index * STAGGER)` stagger, with the constant renamed per job (`STAGGER_SECONDS = 15`,
`= 5`, an inline `* 12`, and the dead `spacing_seconds` heuristic).
The one genuine duplication is the priority `CASE WHEN … positions … watchlist_items … END` SQL
block, copy-pasted between `sync_all_fundamentals_job.rb:38-46` and
`sync_all_statements_job.rb:45-52`.
**Safe to merge?** The SQL, yes — promote it to an `Asset` scope (`Asset.by_holding_priority`);
it is a domain ordering, not job code. The jobs themselves, **no**: their budget arithmetic differs
materially (1 call/asset vs 3 calls/asset against a shared Alpha Vantage quota) and merging them
would put the budget logic behind a conditional, which is where budget bugs live.

**Shape D — one-off shapes (6 jobs). Not duplicated; each is its own thing.**
`SyncSingleAssetJob` (failure-tag dispatch + adaptive backoff), `SyncFundamentalJob`,
`SyncStatementsJob`, `SyncSplitsJob`, `SyncDividendsJob`, `SyncIntegrationJob`,
`SyncMarketIndicesJob`, `SyncIndexHistoryJob`. What these share is not code, it is a *missing*
convention: the `if result.success? … elsif result.failure[0] == :rate_limited … else` ladder appears
in six variants with different severity mappings (compare `sync_single_asset_job.rb:20-36`,
`sync_fundamental_job.rb:16-21`, `refresh_fear_greed_job.rb:45-47`).
**Recommendation:** add `SyncLogging#log_result(task_name, result)` that owns the failure-tag →
severity mapping in one place, and let each job call it. That removes the real duplication (the
policy) without merging jobs that legitimately differ.

**Net:** the family is roughly 4 real merges, not 20. Anyone proposing "consolidate the sync jobs"
should be pointed at Shape B and the Shape C SQL, and stopped at Shapes A and D.

> **S2 Adriana Cienfuegos:** "Twenty jobs for ten providers is not the problem — one job per provider
> is the right granularity when each has its own quota, breaker and symbol dialect. The problem is
> that the *policy* is copied and the *plumbing* is copied, while the thing that should be shared —
> what a rate-limited failure means and how loud it is — is decided independently in six places."

---

## Idempotency summary

| Class | Safe to re-run? | Notes |
|---|---|---|
| Fully idempotent | `TakeSnapshotsJob`, `SyncIndexHistoryJob`, `SyncSplitsJob`, `RefreshFxRatesJob`, `SyncFxHistoryJob`, `SyncCetesJob`, `SyncCetesHistoryJob`, `WarmDiscoverJob`, `PruneTrendScoresJob`, all orchestrators | Unique indexes + `find_or_*` guards, or pure cache writes |
| Idempotent but wasteful | `SyncBulk*Job`, `SyncSingleAssetJob` | Re-publish `AssetPriceUpdated` only when the price actually moved; `recently_synced?` guards the single-asset path |
| **Not idempotent** | `Trading::Domain::SplitAdjuster` via `ProcessEventJob` (JOB-07) | Double-multiplies shares; reachable from Mission Control's retry button |
| **Non-recoverable after partial failure** | `SyncDividendsJob` (JOB-08), `SyncStatementsJob` (JOB-09), `BackfillPriceHistoryJob` (JOB-12) | A crash mid-loop leaves work that no later run will pick up |
| **Leaves stale state on crash** | `SyncIntegrationJob` (JOB-14) | `connection_status: :syncing` with no `ensure` |
| **Unbounded** | `ResolveTrackedSymbolsJob` (JOB-11) | Self-re-enqueues every 60s with no attempt cap |
| **Always fails** | `SyncFxHistoryJob` (JOB-01) | Raises on the log write, every run |

---

## Appendix — job inventory

`Sched.` column: `recurring.yml` line, `event` = EventBus handler, `code` = enqueued from a use
case/controller, **`—` = nothing enqueues it**.

| Job | What it does | Sched. | Delegates to | Idempotent? |
|---|---|---|---|---|
| `ApplicationJob` | Base class; both `retry_on`/`discard_on` commented out (JOB-06) | n/a | — | n/a |
| `ProcessEventJob` | Runs an async EventBus handler | code (`event_bus.rb:12`) | handler class | depends on handler (JOB-07) |
| `SyncPriorityAssetsJob` | Fans out price sync by type+priority; market-hours gated | `:14,19,24` + code | enqueues bulk/single jobs | yes |
| `SyncSingleAssetJob` | One asset price + failure-tag dispatch + adaptive backoff | event + code | logic inline (99 L) | yes (4-min guard) |
| `SyncBulkStocksJob` | Bulk Alpaca US quotes → assets + events | **—** (dead, JOB-04) | logic inline | yes |
| `SyncBulkCryptoJob` | Bulk CoinGecko quotes → assets + events | code (`sync_priority:29`) | logic inline | yes |
| `SyncBulkBmvJob` | Bulk DataBursatil quotes; reports missing symbols honestly | code (`sync_priority:37`) | logic inline | yes |
| `SyncAllAssetsJob` | Fans out per-asset sync with type spacing | **—** (dead, JOB-04) | logic inline | yes |
| `SyncMarketIndicesJob` | Index quotes via yfinance; closes flags off-hours | `:76` | logic inline | yes |
| `SyncIndexHistoryJob` | 5 days of index closes → `MarketIndexHistory` | `:42` | logic inline (JOB-05, JOB-18) | yes |
| `SyncNewsJob` | Articles | `:72` | `MarketData::UseCases::SyncArticles` | yes |
| `SyncEarningsJob` | Earnings calendar | `:88` | `MarketData::UseCases::SyncEarnings` | yes |
| `SyncCetesJob` | CETES auctions → fixed-income assets | `:104` | `MarketData::UseCases::SyncCetes` | yes |
| `SyncCetesHistoryJob` | CETES rate series | `:110` | `MarketData::UseCases::SyncCetesHistory` | yes |
| `SyncFxHistoryJob` | Banxico FIX → `FxRateHistory` | `:34` | `MarketData::UseCases::SyncFxHistory` | **always raises (JOB-01)** |
| `RefreshFxRatesJob` | Current FX rates | `:29` | `FxRatesGateway#refresh_rates` | yes |
| `SyncDividendsJob` | Dividends + `DividendPayment` entitlement | `:96` | logic inline (103 L, JOB-08) | **no** |
| `SyncSplitsJob` | Splits → `SplitDetected` | `:100` | logic inline (JOB-05) | job yes, handler **no** (JOB-07) |
| `SyncAllFundamentalsJob` | Budgeted fan-out of overview syncs | `:80` | `FundamentalsBudget` + enqueue | yes |
| `SyncFundamentalJob` | One asset's overview → `AssetFundamental` | code | logic inline | yes |
| `SyncAllStatementsJob` | Budgeted fan-out of statement syncs | `:84` | `FundamentalsBudget` + enqueue | yes |
| `SyncStatementsJob` | 3 statements for one asset | code | logic inline (JOB-09) | **no** |
| `SyncIntegrationJob` | Probes an integration, sets status | code (`RefreshSync`) | logic inline (JOB-14) | **no** (stuck `syncing`) |
| `BackfillMissingHistoriesJob` | Weekly fan-out for thin histories | `:92` | enqueue only | yes |
| `BackfillPriceHistoryJob` | 365 days OHLCV for one asset | event (`AssetCreated`) + code | logic inline (106 L, JOB-12) | **partial** |
| `TakeSnapshotsJob` | Daily snapshot per portfolio | `:38` | `Portfolio#total_value` (JOB-10) | yes |
| `CalculateTrendScoresJob` | Nightly trend score for every asset | `:46` | logic inline, dup of handler (JOB-13) | yes (appends) |
| `PruneTrendScoresJob` | Bounds `trend_scores`, keeps newest per asset | `:58` | logic inline | yes |
| `DetectTechnicalObservationsJob` | Technical observations | `:50` | `MarketData::UseCases::DetectTechnicalObservations` | yes |
| `RefreshFearGreedJob` | Crypto Fear & Greed reading | `:68` | logic inline | appends a row per run |
| `WarmDiscoverJob` | Warms Descubrir waves + headlines into cache | `:64` | `Discover::WaveRanking` | yes (cache only) |
| `EvaluateDateBasedAlertsJob` | Calendar-driven alert rules | `:122` | `Alerts::UseCases::EvaluateDateBasedRules` | yes (cooldown) |
| `NotifyEarningsJob` | Upcoming-earnings notifications | `:114` | `MarketData::UseCases::NotifyApproachingEarnings` | yes |
| `NotifyMaturitiesJob` | Upcoming-maturity notifications | `:118` | `Trading::UseCases::NotifyApproachingMaturities` | yes |
| `SendDailyDigestJob` | Daily digest | `:128` | `Notifications::UseCases::SendDailyDigest` | yes |
| `CheckSyncHealthJob` | Hourly sync-health sweep → notification | `:136` | logic inline (135 L, JOB-02) | yes (6h dedup) |
| `ResolveTrackedSymbolsJob` | Resolves bare tickers, self-re-enqueues | code (`TrackMissingSymbols:23`) | `SearchTicker` + `CreateAsset` | yes, but **unbounded** (JOB-11) |
| `AdaptiveScheduling` (concern) | Backoff multiplier in Solid Cache | — | — | **never read** (JOB-16) |
| `PausableSync` (concern) | Skips network jobs when `auto_sync_enabled` is off | — | `SiteConfig` | yes |
| `SyncLogging` (concern) | `SystemLog` success/failure helpers | — | — | yes |

**Recurring entries with no job class** (both verified to exist): `cleanup_old_logs` →
`SystemLog…delete_all`, `clear_solid_queue_finished_jobs` → `SolidQueue::Job.clear_finished_in_batches`,
`purge_error_events` → `ErrorEvent.purge_stale!` (`app/models/error_event.rb:16`). No scheduled entry
points at a deleted or renamed class — the drift runs the other way: **two job classes
(`SyncBulkStocksJob`, `SyncAllAssetsJob`) exist with no scheduler and no caller.**

---

## Suggested order of work

1. **JOB-01** (S) — one-line fix; the FX history sync has never once logged.
2. **JOB-02** (M) — stop the false notifications before anything else changes log volume.
3. **JOB-03** (S) — ETFs are invisible; the fix is one scope widening.
4. **JOB-04** (M) — wiring `SyncBulkStocksJob` also repairs the `"Bulk Stock Sync"` monitor.
5. **JOB-05 / JOB-12** (M) — stop reporting success over swallowed failures; JOB-02 depends on this
   being true.
6. **JOB-07 / JOB-08 / JOB-09** (M) — the correctness set: splits, dividends, statements.
7. Everything else.
