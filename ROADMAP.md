# Stockerly — Roadmap

> **Fecha:** 2026-03-03
> **Estado actual:** ~1898 specs, Phase 20.1 complete
> **Siguiente:** Phase 20.2 — Monitoring Enhancements

---

## Completed Phases (0-19) — ~1882 specs

| Fase     | Nombre                              | Specs | Commits |
| -------- | ----------------------------------- | ----- | ------- |
| 0-4      | Setup, Public, Auth, App, Admin     | 85    | —       |
| 4.5-4.6  | Auditorias + Componentes            | 200   | —       |
| 5        | Modelos, Migraciones, Seeds         | 301   | —       |
| 6-6.5    | Backend + Auditoria                 | 540   | —       |
| 7        | Integraciones Externas              | 654   | —       |
| 8        | Polish & Completeness               | 702   | —       |
| **9.0**  | DataSource Registry & SyncLogging   | 887   | 1-5     |
| **9.1**  | Fear & Greed Index                  | 928   | 6-9     |
| **9.2**  | Historical Prices & Real Sparklines | 947   | 10-12   |
| **9.3**  | News Feed with Polygon              | 972   | 13-15   |
| **9.4**  | Market Indices Sync + IPC + VIX     | 988   | 16-18   |
| **9.5**  | CETES Placeholder                   | 990   | 19-20   |
| **10.0** | Foundation: Models + OVERVIEW Sync  | 1050  | 21-24   |
| **10.1** | Financial Statements + Calculator   | 1115  | 25-27   |
| **10.2** | UI: Asset Detail Page               | 1203  | 28-30   |
| **10.3** | Crypto Fundamentals                 | 1216  | 31-32   |
| **11.0** | TrendScore Real Data                | 1238  | 33-36   |
| **11.1** | Trade Entry UI                      | 1281  | 37-42   |
| **11.2** | Quick Wins (F&G Chart, Filters)     | 1295  | 43-45   |
| **11.3** | Earnings External API               | 1306  | 46-48   |
| **12.0** | Email Verification                  | 1318  | 49-53   |
| **12.1** | System Test Expansion               | 1348  | 54-59   |
| **12.2** | Weekly Insight + CI Hardening       | 1363  | 60-63   |
| **13.0** | Sentiment-based Alerts              | 1378  | 64-67   |
| **13.1** | CETES Complete                      | 1393  | 68-72   |
| **13.2** | Performance + Advanced Alerts       | 1415  | 73-76   |
| **14.0** | UX Critical Fixes                   | 1436  | 77-80   |
| **14.1** | Data Integrity (already done 11.1e) | —     | —       |
| **14.2** | Earnings Completion                 | 1458  | 81-83   |
| **14.3** | Trade Management (Edit/Delete)      | 1505  | 84-86   |
| **14.4** | Portfolio Analytics + Alerts         | 1525  | 87-89   |
| **15.0** | Admin & Resilience Foundation       | 1555  | 90-93   |
| **15.1** | Dashboard UX Improvements           | 1565  | 94-96   |
| **15.2** | Sync Resilience & Data Pipeline     | 1578  | 97-99   |
| **15.3** | API Efficiency & Batching           | 1596  | 100-103 |
| **15.4** | Data Completeness & Quality         | 1617  | 104-107 |
| **15.5** | Scaling Strategy & UX Enhancements  | 1627  | 108-109 |
| **15.6** | API Key Management & Rate Limits    | 1697  | 110-116 |
| **16**   | Production Hardening & Security      | 1721  | 117-120 |
| **17**   | Financial Domain Depth               | 1796  | 121-129 |
| **18**   | Analytics Depth & Market Intelligence | 1841  | 130-138 |
| **19**   | Loading States & UX Polish             | 1882  | 139-142 |
| **20.0** | FMP as Fundamentals Fallback           | 1892  | 143-144 |
| **20.1** | PWA Support                            | 1898  | 145-146 |

### Phase 9 Summary (990 specs, 20 commits)

**Infrastructure:** DataSourceRegistry (EventBus pattern), SyncLogging concern, `Integration.requires_api_key`, dynamic admin panel. **Data:** Fear & Greed from Alternative.me + CNN, historical prices from Polygon + CoinGecko, news from Polygon, market indices from Yahoo Finance, CETES placeholder schema. **Key patterns:** Circuit breaker per source, event-driven backfill (`AssetCreated` → `BackfillPriceHistoryJob`), sparkline normalization helper.

### Phase 10 Summary (1216 specs, 12 commits)

**Models:** `FinancialStatement` (JSONB), `AssetFundamental` (JSONB metrics), 33 `MetricDefinitions` (Data.define). **Gateways:** `AlphaVantageGateway` (OVERVIEW + 3 statement endpoints, "Note" key rate limit detection), `CoingeckoGateway#fetch_market_data` (extended crypto data). **Domain:** `FundamentalCalculator` (D/E, TTM, CAGR, all formulas), `FundamentalPresenter` (live P/E, P/B, P/S at render). **UI:** Asset detail page (`/market/:symbol`) with 7 stock tabs + 2 crypto tabs, adaptive rendering, educational tooltips, regulatory disclaimer. **Events:** `FinancialStatementsSynced` → recalculate → `AssetFundamentalsUpdated` → Turbo broadcast.

### Phase 11 Summary (1306 specs, 16 commits)

**TrendScore:** `TrendScoreCalculator` (RSI-14 + 7-day momentum, score blending 60/40), `RecalculateTrendScoreOnPriceUpdate` async handler, `CalculateTrendScoresJob` bulk backfill, removed hardcoded seeds. **Trade Entry:** `ExecuteTradeContract` (dry-validation), `ExecuteTrade` use case with position handling (buy creates/extends, sell closes), `TradesController` (new, create, index), inline Turbo Frame trade form, position locking with `with_lock`, full system test. **Quick Wins:** Historical F&G SVG chart on dashboard, news watchlist filter, earnings watchlist filter. **Earnings API:** `PolygonGateway#fetch_earnings`, `Earnings::SyncCalendar` use case, `SyncEarningsJob` with DataSourceRegistry + recurring schedule.

### Phase 12 Summary (1363 specs, 15 commits)

**Email Verification:** `email_verified_at` migration, `Identity::VerifyEmail` use case, `SendVerificationEmailOnRegistration` handler, `EmailVerificationsController`, persistent banner for unverified users (soft block). **System Tests:** 6 new system specs covering alert management, watchlist management, portfolio tabs, earnings calendar, admin management, password reset flow. **Weekly Insight:** `WeeklyInsightCalculator` domain service (observational language only, no prescriptive advice), "View Full Report" enabled with real portfolio data. **CI Hardening:** Trivy Docker scanning, Bullet gem for N+1 detection, disabled UI button cleanup.

### Phase 13 Summary (1415 specs, 13 commits)

**Sentiment Alerts:** `sentiment_above`/`sentiment_below` conditions in AlertRule enum, `AlertEvaluator` extended with sentiment logic, `EvaluateSentimentAlerts` handler on `FearGreedUpdated`, sentiment options in alert form. **CETES Complete:** `BanxicoGateway` (Banxico SIE API, circuit breaker), `YieldCalculator` (discount rate → yield to maturity), `SyncCetesJob` + events, fixed income detail view with maturity calendar, system test. **Performance:** Composite indexes on `news_articles(related_ticker, published_at)` and `trades(portfolio_id, executed_at)`, N+1 fix via preloaded associations in `Dashboard::Assemble`, Russian doll fragment caching for watchlist table, fragment caching for trending/insight/market_status. **Advanced Alerts:** `volume_spike` condition (threshold × 5-day avg volume), `cooldown_minutes` + `last_triggered_at` on AlertRule, P/E history chart (inline SVG polyline).

### Phase 14 Summary (1525 specs, 13 commits)

**UX Critical Fixes:** Portfolio empty state restructured (always-visible trade form), search modal connected to backend with async fetch + 300ms debounce + keyboard navigation, market listing rows made clickable with Stimulus `row_link_controller`, 30-day SVG area price chart on asset detail page. **Earnings Completion:** Actual EPS sync from Polygon, `beat_miss`/`eps_surprise_percent` methods, beat/miss icons on calendar, full earnings detail page (`/earnings/:id`) with beat status and asset links. **Trade Management:** `Trading::UpdateTrade` use case (30-day edit guard, authorization, position recalculation), `Trading::DeleteTrade` with soft delete (`discarded_at` column), `TradeUpdated`/`TradeDeleted` events with audit log handlers, inline edit form via Turbo Stream, delete with confirmation. **Portfolio Analytics:** `PeriodReturnsCalculator` (8 periods: 1D/1W/1M/3M/6M/1Y/YTD/ALL using snapshots), SVG performance chart on portfolio page with period return pills, `Earnings::NotifyApproaching` use case (3-day lookahead, watchlist + positions, idempotent), `NotifyEarningsJob` daily at 7am.

### Phase 15 Summary (1627 specs, 20 commits)

**Admin & Resilience:** Expandable error details in admin logs (reuse `reveal_controller`), `sync_issue_since` tracking with `RetryFailedAssetsJob` (nightly, auto-disable after 7 days), `daily_api_calls` budget enforcement per Integration with atomic counters, backfill rake tasks with staggered enqueueing. **Dashboard UX:** F&G cards consolidated with inline SVG sparklines (eliminate chart row), `chart_tooltip_controller` Stimulus controller for interactive mousemove tooltips, compact news feed (ticker badge + title + source on single line). **Sync Resilience:** `AdaptiveScheduling` concern (cache-backed 2x backoff, cap 4x), Polygon fallback for market indices via `GatewayChain`, on-demand fundamental sync from asset detail page (10-minute guard). **API Efficiency:** Yahoo batch quotes via `/v7/finance/quote` (-69% calls), unified crypto sync to 5-min interval (-40% CoinGecko), `SyncBulkStocksJob` via Polygon grouped endpoint (-75% stock calls), Alpha Vantage bi-weekly Tue/Fri (-56%). Total API reduction: 2,557→947/day (63%). **Data Completeness:** Daily earnings sync with 90-day `days_ahead` window, `BackfillMissingHistoriesJob` (weekly, assets with <7 histories), integration tests for backfill/recovery/budget flows, `/health` JSON endpoint (ok/degraded/critical, 503 on critical for Kamal). **Scaling:** `ApiKeyPool` model with `KeyRotation` domain service (least-used strategy), TradingView Advanced Chart widget (lazy-loaded via IntersectionObserver, replaces SVG for stocks/ETF/crypto).

### Phase 15.6 Summary (~1697 specs, 7 commits)

**Rate Limiting:** `RateLimiter` domain service with proactive per-minute and per-day checks before HTTP calls, provider-specific limits on Integration (`max_requests_per_minute`, `minute_calls`, `minute_reset_at`), atomic PostgreSQL counters with auto-reset. **Admin CRUD:** `UpdateProvider`, `DeleteProvider`, `AddPoolKey`, `TogglePoolKey`, `RemovePoolKey` use cases with full event audit trail (`IntegrationUpdated`, `IntegrationDeleted`, `PoolKeyAdded`, `PoolKeyToggled`, `PoolKeyRemoved`). **UI:** Redesigned integration cards with rate limit usage bars, expandable API Key Pool section per provider (name, masked key, daily calls, enable/disable toggle), add key form. **Gateway Integration:** `RateLimiter.check!` integrated into all gateways (Polygon, CoinGecko, Alpha Vantage, FxRates) before HTTP calls, 429 detection kept as fallback.

### Phase 16 Summary (~1721 specs, 4 commits)

**Session Security:** Cookie-based session with 12-hour absolute expiry, 30-minute inactivity timeout with `check_session_timeout` before_action, session timestamp tracking via `last_activity_at` and `session_started_at`. **Audit Logging:** `UserLoggedIn` and `UserLoginFailed` events with IP/user agent tracking, `CreateAuditLogOnLogin`, `CreateAuditLogOnLoginFailure` (only logs when user exists), and `CreateAuditLogOnPasswordChange` handlers wired to EventBus. **IDOR Tests:** 8 controller-level authorization specs verifying user A cannot access user B's watchlist items, alert rules, notifications, or trades. **Structured Logging:** `lograge` gem with JSON formatter for production, `append_info_to_payload` injecting `user_id` and client IP into every request log. Skipped: `.env.production` removal (never committed), Rack::Attack (Rails 8.1 native `rate_limit` already on all sensitive endpoints), PostgreSQL backups (infrastructure task).

### Phase 17 Summary (~1796 specs, 9 commits)

**Portfolio Benchmarking:** `MarketIndexHistory` model for daily index close prices, `TimeWeightedReturn` domain service (TWR = ∏(1 + R_i) - 1), benchmark comparison overlay on portfolio chart with S&P 500, NASDAQ, Dow Jones selection, `SyncIndexHistoryJob` via Yahoo Finance (daily 11:15pm). **Dividend Tracking:** `FmpGateway` for Financial Modeling Prep API (dividends + splits), `SyncDividendsJob` with `DividendsSynced` event pipeline (weekly Monday 8am), `UpcomingDividendsPresenter` showing expected payouts on portfolio dividends tab. **Stock Splits:** `StockSplit` model, `SplitAdjuster` domain service adjusts positions (shares × ratio, avg_cost ÷ ratio) and pre-split trades, `SyncSplitsJob` (weekly Monday 9am), `SplitDetected` → async `AdjustPositionsOnSplit` handler. **Position Annotations:** `notes` (text) and `labels` (text[] array, max 10) on positions, `PositionsController#update` scoped to current user, label pills and notes icon tooltip on position rows. Trade export (CSV/PDF) deferred to nice-to-have phase.

### Phase 18 Summary (~1841 specs, 9 commits)

**Risk Metrics:** `PortfolioRiskCalculator` domain service (annualized volatility σ×√252, Sharpe ratio vs CETES 28D yield, max drawdown peak-to-trough), `RiskMetrics` Dry::Struct, 31-snapshot minimum guard with "Not enough data" empty state, 3-column display on portfolio page. **Allocation Enrichment:** `allocation_by_asset_type` method on Portfolio model, tabbed sidebar view (By Sector / By Type) reusing `_donut_chart.html.erb`. **Asset Detail Enrichment:** Earnings tab with EPS bar chart and beat/miss badges (last 8 quarters), analyst target price card with upside/downside % and 52-week range bar, volume bars on SVG price chart (30% height, semi-transparent). **Market Intelligence:** Market indices card showing symbol, value, change% (color-coded), mini sparklines from last 5 history points (replaces simple open/closed status), Fear & Greed sub-indicators collapsible section (7 CNN components with progress bars), dividend payment history table with annual summary cards. **Zero new migrations** — all data already existed in the schema.

### Phase 19 Summary (~1882 specs, 4 commits)

**Skeleton Loader:** Reusable `_skeleton.html.erb` component (text, card, stat_card, table_row variants) with CSS shimmer animation, `progress_bar_controller.js` Stimulus controller for Turbo page transitions. **Lazy Tabs:** Turbo Frame `loading="lazy"` on Earnings and Statements tabs in asset detail page, separate controller endpoints rendering without layout. **Empty States:** Standardized all empty states across portfolio, alerts, earnings, market views to reusable `_empty_state.html.erb` component (icon, title, description, optional CTA). **Dashboard Lazy Loading:** News feed and trending sidebar extracted to independent Turbo Frame endpoints (`/dashboard/news_feed`, `/dashboard/trending`) with skeleton placeholders, reducing initial dashboard payload.

### Phase 20.0 Summary (~1892 specs, 2 commits)

**FMP Fundamentals Fallback:** `FmpGateway#fetch_overview` maps `/api/v3/profile/{symbol}` to Alpha Vantage schema (`companyName`→`name`, `mktCap`→`market_cap`, `pe`→`pe_ratio`, `lastDiv`→`dividend_per_share`, `range`→52-week high/low, `dcf`→`analyst_target_price`). `GatewayChain#fetch_overview` iterates gateways with circuit breaker support (same pattern as `fetch_price`). `SyncFundamentalJob` refactored to use chain: Alpha Vantage primary (25/day) → FMP fallback (250/day). 10x budget increase for fundamentals sync.

### Phase 20.1 Summary (~1898 specs, 2 commits)

**PWA Support:** `manifest.json` (standalone display, `#004a99` theme, SVG + PNG icons), service worker with network-first navigation (offline fallback page), cache-first Google Fonts, stale-while-revalidate for static assets (CSS/JS/images). Pre-caches offline page and icons on install. Old cache cleanup on activate. Service worker registration in `application.js`. Layout updated with `<link rel="manifest">`, `<meta name="theme-color">`, and `apple-mobile-web-app-status-bar-style`.

### Key Architecture Decisions (Phases 9-20)

| Decision | Resolution |
|----------|-----------|
| MetricDefinition storage | Ruby module (Data.define), not DB table |
| Price-dependent metrics | FundamentalPresenter computes live at render |
| Debt-to-Equity formula | `total_debt / equity` (NOT total_liabilities) |
| Guidance language | Contextual only, no prescriptive "buy/sell" |
| GAAP vs Non-GAAP | GAAP only, noted in UI |
| API priority | OVERVIEW first (50+ metrics/1 call), then statements |
| Alpha Vantage rate limit | Inspect body for "Note" key (returns HTTP 200, not 429) |
| Crypto adaptive rendering | Stocks: 7 tabs, Crypto: 2 tabs (Summary + Market Data) |
| Crypto fundamentals storage | `period_label: "CRYPTO_MARKET"` in AssetFundamental |
| TrendScore formula | 60% normalized RSI-14 + 40% normalized 7-day momentum |
| Email verification | Soft block (banner), not hard redirect |
| Weekly insight language | Strictly observational, disclaimer footer reused |
| CETES yield calculation | Discount rate → yield to maturity (Mexican convention) |
| Fragment caching | Russian doll for watchlist rows, time-based for static sections |
| Volume spike detection | Current volume ≥ threshold × 5-day average |
| Alert cooldown | `cooldown_minutes` (default 60) + `last_triggered_at` |
| P/E chart | Inline SVG polyline (same pattern as F&G), no external JS |
| Trade soft delete | `discarded_at` column — audit trail critical for fintech |
| Trade edit limit | 30 days, admin override possible |
| Beat/miss threshold | Straight comparison: `actual >= estimated` = beat |
| Portfolio chart default | 3M — balances recency with perspective |
| Snapshots timing | Midnight UTC — simpler, no timezone complexity |
| Earnings alerts advance | 3 days before report_date |
| sync_issue recovery | `RetryFailedAssetsJob` nightly, auto-disable after 7 days |
| API budget enforcement | Atomic `update_counters` per Integration, daily reset |
| Yahoo batch endpoint | `/v7/finance/quote?symbols=X,Y,Z` — single call for all symbols |
| Crypto sync frequency | Unified 5-min interval (288 calls/day, within CoinGecko free tier) |
| Alpha Vantage frequency | Bi-weekly Tue/Fri, 15s stagger between jobs |
| Adaptive scheduling | Cache-backed backoff (2x per rate_limit, cap 4x, reset on success) |
| Health endpoint | `/health` JSON, 503 on critical — Kamal compatible |
| API key rotation | Least-used strategy via `KeyRotation` domain service |
| TradingView widget | Advanced Chart, lazy IntersectionObserver, `EXCHANGE:SYMBOL` mapping |

| RateLimiter vs CircuitBreaker | Separate domain services — RateLimiter prevents quota overuse (proactive), CircuitBreaker handles failures (reactive) |
| Rate limit granularity | Per-minute + per-day on Integration (two most common intervals across providers) |
| Rate limit storage | PostgreSQL counters with atomic `update_counters` — no Redis needed at current scale |
| Proactive rate limiting | `RateLimiter.check!` before HTTP call, 429 detection kept as fallback |
| ApiKeyPool naming | `name` field for human-readable identification without revealing key values |
| Pool key deletion | Hard delete (pool keys are operational, not financial audit trail) |
| Integration deletion | Allowed from admin — cascades `dependent: :destroy` to pool keys |
| Monthly rate limits | Modeled as daily ÷ 30 (ExchangeRate API: 1,500/month ≈ 50/day) |
| Backup storage | S3-compatible (Backblaze B2) — cost-effective, Kamal-compatible |
| Session timeout | 30-min inactivity + 12-hour absolute — standard fintech practice |
| Rate limiting layer | Rails 8.1 native `rate_limit` on controllers + RateLimiter for providers — Rack::Attack unnecessary |
| TWR vs MWR | TWR first (industry standard, eliminates cash flow noise) — MWR in v3 |
| Dividend data source | FMP free tier (250/day) — replaces Polygon for corporate actions |
| Split handling | Retroactive cost basis adjustment via domain service on `SplitDetected` event |
| Risk metrics | Volatility + Sharpe + Max Drawdown — calculable from existing snapshots |
| Composite alerts | JSONB conditions array with AND/OR — no full expression tree |
| Sector comparison | GROUP BY existing `asset.sector` — no new data source needed |
| LLM integration | CLI Bridge microservice (separate repo), NOT direct API/SDK |
| LLM provider routing | CLI subprocess per provider — `claude -p`, `gemini -p`, `codex exec` |
| LLM data anonymization | Only tickers, percentages, relative changes — never PII |
| LLM output validation | `LlmResponseContract` (Dry::Validation) before data enters domain |
| Risk-free rate source | CETES 28D yield from DB (no new gateway calls) |
| Risk minimum data | 31 snapshots (30 daily returns) for meaningful volatility |
| Volatility formula | Annualized σ = daily σ × √252 (standard financial convention) |
| Sharpe formula | (annualized TWR - risk_free_rate) / annualized_volatility |
| Allocation by type | New method on Portfolio, same pattern as existing `allocation_by_sector` |
| Earnings display | Last 8 quarters — typical analyst view window |
| Volume bars scaling | Relative (% of max volume) — keeps SVG proportional |
| Index sparklines | Last 5 data points from `market_index_histories` — lightweight |
| F&G sub-indicators | 7 CNN components already stored — pure view work |
| Turbo Frame lazy loading | `loading="lazy"` with skeleton placeholders — IntersectionObserver defers fetch |
| Dashboard lazy sections | News feed + trending as separate endpoints, reduces initial payload |
| Error tracking | Honeybadger (Rails-first, 15-day retention on free tier) over Sentry/Bugsnag |
| FMP overview mapping | Map FMP camelCase to Alpha Vantage schema — GatewayChain transparent fallback |
| Fundamentals chain | Alpha Vantage primary → FMP fallback via GatewayChain (same pattern as fetch_price) |
| PWA display mode | `standalone` — feels like native app, no browser chrome |
| Service worker strategy | Network-first navigation (offline fallback), stale-while-revalidate for assets, cache-first for fonts |
| PWA icons | SVG (any size) + PNG 192×512 — covers all platforms |

---

## Upcoming Phases (20.2-22)

> **Objetivo:** Production readiness, analytics depth, AI intelligence
> **Note:** Phase 20.0 (FMP Fundamentals Fallback) and 20.1 (PWA Support) completed 2026-03-03. Honeybadger error tracking added ahead of schedule.

---

## Phase 20 — Provider Upgrade & Production Readiness

> **Theme:** "Better data, fewer limits, production-ready"
> **Owner:** Data Engineer + DevOps Engineer
> **Estimated specs:** ~22

### ~~20.0 — FMP as Fundamentals Fallback~~ (Done)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| ~~143~~ | ~~Extend FmpGateway with company profile and fundamentals~~ | ~~Add `fetch_overview` to existing gateway~~ | ~~+10~~ |
| ~~144~~ | ~~Add FMP as fallback in GatewayChain for fundamentals~~ | ~~Chain config, circuit breakers, event source tracking~~ | ~~+0~~ |

### ~~20.1 — PWA Support~~ (Done)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| ~~145~~ | ~~Add PWA manifest, service worker, and offline page~~ | ~~manifest.json, service worker, icons, offline.html~~ | ~~+4~~ |
| ~~146~~ | ~~Add cache strategy for fonts and stale-while-revalidate~~ | ~~Google Fonts cache, stale-while-revalidate for assets~~ | ~~+2~~ |

### 20.2 — Monitoring Enhancements

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 147 | Add health dashboard improvements (job queue depth, cache hit rate) | Admin view, domain service, Solid Queue metrics | +4 |

> **Note:** Error tracking (Honeybadger) already integrated ahead of Phase 20. See commit `364a161`.

**Phase 20 Total: ~17 specs, ~5 commits**

---

## Phase 21 — Concentration Alerts & Enhanced TrendScore

> **Theme:** "Smarter scoring, risk-aware alerts"
> **Owner:** Financial Expert + Domain Architect
> **Estimated specs:** ~20
> **Rationale:** Concentration risk data already available via `allocation_by_sector` and `allocation_by_asset_type`. TrendScore currently uses only RSI-14 + 7-day momentum (2 factors) — adding MACD, volume, and fundamentals weight creates a meaningful scoring upgrade.

### 21.0 — Concentration Alerts

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 149 | Add ConcentrationAnalyzer domain service | HHI index, single-position %, sector % thresholds, risk levels | +6 |
| 150 | Add concentration_risk condition to AlertRule with dashboard warnings | Migration, AlertEvaluator extension, portfolio sidebar badges | +6 |

### 21.1 — Enhanced TrendScore

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 151 | Enhance TrendScoreCalculator with MACD, volume, and EMA factors | Add 3 new factors (MACD signal, volume trend, EMA crossover), reweight to 5-factor blend | +5 |
| 152 | Add TrendScore breakdown tooltip on market listings | Show per-factor scores in metric tooltip, color-coded contribution bars | +3 |

**Phase 21 Total: ~20 specs, ~4 commits**

---

## Phase 22 — LLM-Powered Intelligence Layer

> **Theme:** "Delegate research and analysis to AI you already pay for"
> **Owner:** Domain Architect + Data Engineer + Rails Engineer
> **Estimated specs:** ~65
> **External dependency:** SheLLM service (separate repo — see `SHELLM_PLAN.md`)

### Architecture

Stockerly does NOT call LLM APIs directly. Instead, it communicates with an independent **SheLLM** microservice that wraps CLI tools (claude, gemini, codex) via existing subscriptions. No API keys needed.

```
Stockerly                     SheLLM (separate repo)          CLI Subscriptions
                              (Node.js + Express)
LlmGateway ──► POST ──►  /completions ──► subprocess ──► claude -p "..."
(Faraday)      JSON        route by           spawn        gemini -p "..."
             ◄── JSON ◄──  provider  ◄── parse stdout ◄── codex exec "..."
```

### 22.0 — Stockerly LLM Gateway

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 153 | Add LlmGateway with Faraday client to SheLLM | Gateway, CircuitBreaker, RateLimiter integration | +8 |
| 154 | Add SheLLM Integration seed and admin health indicator | Seeds, admin view, health check | +4 |
| 155 | Add LlmResponseContract for output validation | Contract, Dry::Validation, JSON schema enforcement | +6 |

### 22.1 — Portfolio Insight Generator

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 156 | Add InsightGenerator domain service with analysis prompt | Domain service, system prompt template, anonymizer | +8 |
| 157 | Add GeneratePortfolioInsightsJob as daily recurring job | Job (11:15pm after snapshots), events, handlers | +6 |
| 158 | Add AI insight card to dashboard with attribution label | Views, Turbo Frame, opt-out toggle, "AI-generated" label | +4 |

### 22.2 — News Sentiment Analysis

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 159 | Add NewsSentimentAnalyzer domain service with batch processing | Domain service, batch prompt (10 articles per call) | +8 |
| 160 | Add AnalyzeNewsSentimentJob triggered after news sync | Job, event handler, migration (sentiment columns on news_articles) | +6 |
| 161 | Add sentiment badges and filter to news feed | Views, filter, Turbo Frame update | +4 |

### 22.3 — Fundamental Health Checks

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 162 | Add FundamentalHealthCheck domain service | Domain service, prompt template, 7-day cache | +6 |
| 163 | Add AI health check section to asset detail page | Views, Turbo Frame, cache integration | +4 |

### 22.4 — Earnings Narrative

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 164 | Add EarningsNarrativeGenerator for earnings detail page | Domain service, views, cache | +5 |

**Phase 22 Total: ~65 specs, ~12 commits**

---

## Summary & Sequencing

### Phase Dependency Graph

```
Phase 16 (Security) ──────────────────► Production-ready ✅
    │
Phase 17 (Financial Domain) ─────────► User value (benchmarking, dividends, splits) ✅
    │
Phase 18 (Analytics Depth) ──────────► Data depth (risk, earnings, volume, indices) ✅
    │
Phase 19 (UX Polish) ───────────────► Loading states, lazy tabs, empty state consistency ✅
    │
Phase 20 (Production Readiness) ────► FMP fallback, PWA, health dashboard ← NEXT
    │
Phase 21 (Smart Analytics) ─────────► Concentration alerts, enhanced TrendScore
    │
Phase 22 (LLM Intelligence) ────────► AI insights (requires SheLLM deployed)
    ▲
    │ External dependency: SheLLM (separate repo)
    │ See SHELLM_PLAN.md
```

### Totals

| Phase | Theme | Commits | Estimated Specs | Running Total |
|-------|-------|---------|-----------------|---------------|
| ~~16~~ | ~~Production Hardening~~ | ~~4~~ | ~~24~~ | ~~1721~~ |
| ~~17~~ | ~~Financial Domain~~ | ~~9~~ | ~~75~~ | ~~1796~~ |
| ~~18~~ | ~~Analytics Depth~~ | ~~9~~ | ~~45~~ | ~~1841~~ |
| ~~19~~ | ~~UX Polish~~ | ~~4~~ | ~~41~~ | ~~1882~~ |
| ~~20.0~~ | ~~FMP Fundamentals Fallback~~ | ~~2~~ | ~~10~~ | ~~1892~~ |
| ~~20.1~~ | ~~PWA Support~~ | ~~2~~ | ~~6~~ | ~~1898~~ |
| 20.2 | Monitoring Enhancements | 1 | ~4 | ~1902 |
| 21 | Smart Analytics | 4 | ~20 | ~1922 |
| 22 | LLM Intelligence | 12 | ~65 | ~1987 |
| | **Total Remaining** | **~17** | **~89** | **~1987** |

### External Dependencies

| Dependency | Repository | Status | Required By |
|---|---|---|---|
| **SheLLM** | `shellm` | Plan ready (`SHELLM_PLAN.md`) | Phase 22 |

---

## Deferred to v3+

| Feature | Reason | Expert |
|---------|--------|--------|
| **Composite Alerts (AND/OR)** | JSONB conditions refactor adds schema complexity and input validation risk. Concentration alerts cover 80% of the need. | Security Engineer + Domain Architect |
| **Portfolio Beta** | Correlation vs benchmark index. Requires position-level daily returns. | Financial Expert |
| **Weekly Insight Improvement** | Fix `change_percent_24h` bug, add 7-day return calculation. | Domain Architect |
| **Tax Lot Tracking (FIFO/LIFO)** | Complex, requires cost lot model + tax regime selection. Do after trade export validates demand. | Financial Expert |
| **Profile Sharing / Privacy Mode** | No community features yet. Zero demand signal. | Domain Architect |
| **Performance Attribution by Position** | Requires position-level snapshots (expensive storage). After TWR proves value. | Financial Expert |
| **Wash Sale Detection** | US-specific tax rule. Not relevant for Mexican market. | Financial Expert |
| **Options/Warrants Tracking** | Entirely different asset class with Greeks, chains, expiry. Separate product. | Domain Architect |
| **Trade Export (CSV/PDF)** | Deferred from Phase 17 to nice-to-have. Not urgent for current user needs. | Product Strategist |
| **Real-time WebSocket Prices** | Polygon WebSocket is paid tier. Current polling is sufficient for 5-min updates. | Data Engineer |
| **Multi-tenancy / Team Portfolios** | Authorization model overhaul. No demand. | Domain Architect |
| **BulkAssetSync Concern** | DRY refactor of bulk sync jobs — low urgency, already working | Rails Backend |
| **SSL End-to-End** | Kamal proxy SSL + Cloudflare Full Strict or Tunnel | DevOps |

---

## Protocol

1. **Read this ROADMAP.md** — identify which phase and step you're on
2. **Run `bundle exec rspec`** — confirm all specs pass before starting
3. **Implement step by step** — one commit per step, tests included
4. **Run `bundle exec rspec`** after each commit — keep green always
5. **Run `bin/rubocop`** — no offenses

### Commit Convention

- Imperative mood ("Add feature" not "Added feature")
- First line under 70 characters
- One commit per logical step
