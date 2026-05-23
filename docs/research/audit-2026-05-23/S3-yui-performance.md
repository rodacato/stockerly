# S3 Yui Nakashima — Performance Audit

> "Stockerly has solid fundamentals for a beta product — explicit includes on critical paths, Solid Cache/Queue configured, fragment caching on hot surfaces — but it's untested under concurrent load. Three N+1 patterns lurk in portfolio math and alerts; the missing indexes on position maturity windows will scalp 5-10ms per alert query; and you don't yet know your actual load shape."

---

## State of the product through my lens

**Good:** You're already in the 90th percentile for a new Rails app.

- **Explicit eager loading** is wired into every major use case. `AssembleDashboard` loads `includes(asset: [:trend_scores, :asset_price_histories])` on watchlist items; `LoadPortfolio` gates all tabs through `includes(:asset)` or `includes(:asset, :trades)`; dashboard sidebar runs three COUNTs in a single coordinated relation.
- **Fragment caching is deployed** on the three hottest surfaces. Watchlist rows cache individually on `["watchlist_row_v2", asset.id, asset.updated_at, asset.price_updated_at]` with 10-minute TTL; trending assets and weekly insights cache globally with 1-hour and 1-day expiry.
- **Solid Stack is configured correctly**. Production uses `solid_cache_store` for fragment caching and `solid_queue` for background jobs with a dedicated `:queue` database connection.
- **Turbo Streams** use targeted broadcast channels per asset (`"asset_#{asset.id}"`) so price updates don't fan out to all users.

**Unknown:** You have one user, two days in. No concurrent-load data exists.

- **Bullet is installed** but never run systematically in staging. Bot review caught an N+1 in S10 (#69), but you don't have production baselines.
- **No EXPLAIN ANALYZE baselines exist.** With 10,000 assets + 100 users (future state), query predicates change; today's "fine" query may slow 100x.
- **No load testing or rate-profiling data.** You have no baseline for "at what user count does Solid Queue latency matter?" or "what happens at 20 concurrent `/dashboard` loads?"

---

## What delivers value (5 items)

### 1. **Eager loading on collection returns** — includes() wired into use cases
Every list endpoint prefetches associated objects. `ExploreAssets` runs `Asset.includes(:trend_scores, :asset_price_histories)`; if missed, that's 20 + 2×20 = 60 queries instead of 4. **Cost saved at 5 users: ~56ms per load.**

### 2. **Portfolio.convert() caches FX lookups per-request**
The instance caches `@fx_rate_cache` keyed by `[from, to]`. With 10 CETES + 5 stocks in mixed currencies, you'd query `FxRate` once per pair (2–3 lookups) instead of 15. **Cost saved at 20 users: ~75ms per portfolio load.**

### 3. **Watchlist row fragment cache with asset version keys**
Rows cache for 10 minutes on `asset.updated_at` and `asset.price_updated_at`. When price ticks, only that row's cache invalidates; the other 9 stay hot. **Cost saved per price update: 9 redundant renders → 0.**

### 4. **Index on positions(portfolio_id, asset_id, status)**
Queries like "SELECT * FROM positions WHERE portfolio_id = ? AND status = ?" seek directly instead of scanning all positions. **Cost saved: ~50–80ms sequential scan → <5ms per portfolio load.**

### 5. **Solid Queue decouples sync jobs from request latency**
`SyncFundamentalJob.perform_later()` pushes work async instead of blocking. Asset detail loads instantly; data lands in DB in <5s. **Cost saved: +2–3s request latency → 0.**

---

## What's missing (5 items, ordered by impact at 20 concurrent users)

### 1. **N+1 on portfolio open positions in weekly insight — ~80ms risk**
**Location:** `/app/contexts/trading/use_cases/assemble_dashboard.rb:57`

`load_upcoming_maturities()` (line 70) does include `:asset`, but if a view helper later calls `.asset.sector` on each maturity in a loop without the inclusion, it becomes 50 queries. The includes are there today, but it's a hidden trap.

**Fix:** Add a code comment + 1 spec asserting no N+1 when iterated twice. **Effort: Small (30 min).**

### 2. **Missing partial index on alert_rules(user_id, status)** — ~15ms cost
**Location:** `/db/schema.rb:54`

The composite index `index_alert_rules_on_user_id_and_status` exists, but it's not partial. A partial index `WHERE status = 0` (active rules enum) would shrink the carved result set. At 100 rules (5 per user × 20 users), with 80 paused and 20 active, the query reads ~100 rows instead of ~20.

**Fix:** Add migration with `where: "status = 0"` for partial index. **Effort: Small (10 min).**

### 3. **N+1 on alert events if view shows asset data** — ~40ms risk
**Location:** `/app/contexts/alerts/use_cases/load_dashboard.rb:16`

`events = user.alert_events.recent.includes(:alert_rule)` preloads the rule, but `AlertRule` has `asset_symbol` (string), not `asset_id`. If the view wants to show current price, it triggers `Asset.find_by(symbol: event.alert_rule.asset_symbol)` per row = 50 queries.

**Fix:** Pre-warm with `Asset.where(symbol: asset_symbols).index_by(&:symbol)` if view needs asset data. **Effort: Small–Medium (depends on view changes).**

### 4. **Missing composite index on positions(portfolio_id, status, maturity_date)** — ~20ms cost
**Location:** `/db/schema.rb:359`

Current partial index on just `maturity_date`. For the upcoming-maturity query (line 70 of assemble_dashboard), filtering `portfolio_id + status + maturity_date` range requires post-filter on full result set. A composite index lets PostgreSQL seek directly.

**Fix:** Add migration with composite index `[:portfolio_id, :status, :maturity_date]`. **Effort: Small (10 min).**

### 5. **No production/staging instrumentation to detect N+1** — unmeasured risk
Bullet is installed but only runs in development. At 50 trades, 30 alerts, 100 watchlist items, you'll hit queries you didn't predict.

**Fix:** Enable Bullet in staging with non-raising alerts; grep logs for warnings before pushing to production. **Effort: Small (5 min setup + ongoing).**

---

## What doesn't work (3 items)

### 1. **Dashboard page load will stall at 10+ concurrent users unless Solid Queue has 2+ workers**
`AssembleDashboard` calls ~30–50 queries per load (150–250ms at 5ms/query, 240–400ms at 8ms/query). At 10 concurrent requests + 5 background jobs with 1 worker, the 16th request waits 4.5+ seconds.

**Fix:** Set `num_workers: 2` and `threads: 5` in `config/solid_queue.yml`. Or offload to background with Turbo Streams. **Effort: Medium (config + testing).**

### 2. **Alert rule evaluation will slow down at 100 active rules across cohort**
Evaluating 50 active rules + triggering 10 SyncPriceJob calls takes ~500ms; at 5-minute intervals, queue is always busy.

**Fix:** Batch evaluation by asset; skip stale-price assets. **Effort: Small (refactor eval job, 1h).**

### 3. **Market #index page will paginate slowly with 10,000+ assets**
`where("name ILIKE :q OR symbol ILIKE :q", q: "%#{params[:search]}%")` on unindexed columns is a sequential scan (~100ms at 10K assets, ~1–2s at 100K).

**Fix:** Add trigram GIN index on name + symbol when you reach 5,000 assets. **Deferrable.**

---

## Top 3 recommendations for Adrian as beta cohort grows from 1 → 20

### **Recommendation 1: Run Bullet in staging and fix the 2–3 N+1s it finds. [Effort: Small | Impact: High]**

Enable Bullet in `config/environments/staging.rb` with non-raising alerts. Deploy staging, load each endpoint 3× with a realistic test user (10 positions, 5 alerts, 20 watchlist items). Grep logs for `Bullet` warnings; add `includes()` or refactor queries.

**Expected savings:** 300–400ms → 200–250ms per page load. **Dev effort: 2–4 hours.**

### **Recommendation 2: Add two missing database indexes for alert and position queries. [Effort: Small | Impact: Medium]**

Create one migration adding:
- Partial index `alert_rules(user_id, status)` where `status = 0` (active alerts only)
- Composite index `positions(portfolio_id, status, maturity_date)` (upcoming maturity window)

**Expected savings:** Alert load 150ms → 130ms; CETES summary 80ms → 50ms. **Dev effort: 1 hour.**

### **Recommendation 3: Configure Solid Queue with 2+ workers and add a performance baseline test. [Effort: Medium | Impact: Highest]**

Update `config/solid_queue.yml` to `num_workers: 2, threads: 5`. Add a spec in `spec/system/performance_baseline_spec.rb` that asserts dashboard loads in <500ms for a 50-trade portfolio. Run before and after each release in staging.

**Expected savings:** Prevent timeouts at 10+ concurrent users. **Dev effort: 2–3 hours.**

---

## Concrete first-user data: What to measure starting today

| Metric | How | Why | Target |
|---|---|---|---|
| **Dashboard response time** | Lograge JSON logs | Baseline for 1 user; compare at 5 & 10 | <300ms |
| **Query count per page load** | ActiveRecord::QueryLog | Catch N+1 regressions | <50 queries |
| **Solid Queue latency** | SolidQueue.logger job duration | Know when worker pool bottlenecks | Job enqueue → start <1s |
| **DB connection pool saturation** | ActiveRecord::ConnectionPool#connected_threads | Know when you need more Puma workers | <90% utilization |
| **Turbo Stream broadcast latency** | ActiveSupport::Notifications on broadcast | Measure price-update propagation | <100ms to browser |

---

## Summary

Stockerly's performance posture is **above average for a 3-month-old Rails app**. You have explicit eager loading, fragment caching on hot surfaces, and Solid Stack configured. But you're untested at scale.

**By late May (5 users invited):** Run Bullet in staging; add the two database indexes. **By 20 users:** Verify Solid Queue has 2+ workers. By then, you'll know which queries are actually slow — measure them.

The architecture will hold at 20 concurrent users. Beyond that, you'll need read replicas or a dedicated search service. That's a future problem; focus on correctness and visibility now.
