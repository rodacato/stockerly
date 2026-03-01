# Stockerly — Roadmap

> **Fecha:** 2026-03-01
> **Estado actual:** ~1697 specs, Phase 15.6 complete
> **Siguiente:** Phase 16 — Production Hardening & Security

---

## Completed Phases (0-15.6) — ~1697 specs

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

### Key Architecture Decisions (Phases 9-15)

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
| Rate limiting layer | Rack::Attack for HTTP + RateLimiter for provider — separate concerns |
| TWR vs MWR | TWR first (industry standard, eliminates cash flow noise) — MWR in v3 |
| Dividend data source | FMP free tier (250/day) — replaces Polygon for corporate actions |
| Split handling | Retroactive cost basis adjustment via domain service on `SplitDetected` event |
| CSV sanitization | Strip `=`, `+`, `-`, `@` prefixes — prevent formula injection |
| Dark mode toggle | `localStorage` + Stimulus controller — no server roundtrip |
| i18n scope | Critical strings only (nav, buttons, labels, errors) — not full views |
| Risk metrics | Volatility + Sharpe + Max Drawdown — calculable from existing snapshots |
| Composite alerts | JSONB conditions array with AND/OR — no full expression tree |
| Sector comparison | GROUP BY existing `asset.sector` — no new data source needed |
| LLM integration | CLI Bridge microservice (separate repo), NOT direct API/SDK |
| LLM provider routing | CLI subprocess per provider — `claude -p`, `gemini -p`, `codex exec` |
| LLM data anonymization | Only tickers, percentages, relative changes — never PII |
| LLM output validation | `LlmResponseContract` (Dry::Validation) before data enters domain |

---

## Commit Sequence

### Phases 9-13 (Completed — 76 commits)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
| 1   | 9.0a   | Add requires_api_key to Integration model                               | +2    |
| 2   | 9.0b   | Add DataSourceRegistry with source metadata                             | +6    |
| 3   | 9.0c   | Add SyncLogging concern for standardized job logging                    | +2    |
| 4   | 9.0d   | Refactor sync jobs to use SyncLogging and DataSourceRegistry            | +0    |
| 5   | 9.0e   | Replace hardcoded admin buttons with registry-driven data sources panel | +0    |
| 6   | 9.1a   | Add FearGreedReading model and migration                                | +8    |
| 7   | 9.1b   | Add crypto and stock Fear & Greed gateways                              | +11   |
| 8   | 9.1c   | Add RefreshFearGreedJob with events and handler                         | +10   |
| 9   | 9.1d   | Display Fear & Greed indices on dashboard                               | +6    |
| 10  | 9.2a   | Add historical price fetch to Polygon and CoinGecko gateways            | +6    |
| 11  | 9.2b   | Add BackfillPriceHistoryJob triggered on asset creation                 | +5    |
| 12  | 9.2c   | Connect sparklines to real price history data                           | +7    |
| 13  | 9.3a   | Add fetch_news method to PolygonGateway                                 | +4    |
| 14  | 9.3b   | Add SyncNewsJob with Polygon news integration                           | +8    |
| 15  | 9.3c   | Enhance news page with infinite scroll, filters, and TradingView widget | +8    |
| 16  | 9.4a   | Add fetch_index_quotes to YahooFinanceGateway                           | +4    |
| 17  | 9.4b   | Add SyncMarketIndicesJob with Yahoo Finance                             | +6    |
| 18  | 9.4c   | Add IPC index, VIX indicator, and live index display                    | +5    |
| 19  | 9.5a   | Add fixed_income asset type with yield and maturity fields              | +3    |
| 20  | 9.5b   | Add fixed income badge and filter in market UI                          | +2    |
| 21  | 10.0a  | Add FinancialStatement and AssetFundamental models                      | +10   |
| 22  | 10.0b  | Add MetricDefinitions module with 30+ metric definitions                | +4    |
| 23  | 10.0c  | Add AlphaVantageGateway with OVERVIEW endpoint                          | +6    |
| 24  | 10.0d  | Add OVERVIEW sync pipeline with FundamentalPresenter                    | +10   |
| 25  | 10.1a  | Add financial statement fetch methods to AlphaVantageGateway            | +4    |
| 26  | 10.1b  | Add FundamentalCalculator with all metric formulas                      | +10   |
| 27  | 10.1c  | Add statement sync pipeline with FundamentalCalculator                  | +11   |
| 28  | 10.2a  | Add asset detail page with summary tab and metric cards                 | +8    |
| 29  | 10.2b  | Add category tabs, statements tab, and navigation links                 | +6    |
| 30  | 10.2c  | Add metric tooltip controller with help icon popovers                   | +6    |
| 31  | 10.3a  | Enrich CoinGecko gateway with extended market data                      | +3    |
| 32  | 10.3b  | Add crypto-specific metrics with adaptive rendering                     | +7    |
| 33  | 11.0a  | Add TrendScoreCalculator domain service with RSI-14                     | +8    |
| 34  | 11.0b  | Add RecalculateTrendScoreOnPriceUpdate event handler                    | +4    |
| 35  | 11.0c  | Add CalculateTrendScoresJob for bulk backfill                           | +4    |
| 36  | 11.0d  | Remove hardcoded trend scores, update MarketSentiment fallbacks         | +4    |
| 37  | 11.1a  | Add ExecuteTradeContract with dry-validation                            | +6    |
| 38  | 11.1b  | Add ExecuteTrade use case with position handling                        | +10   |
| 39  | 11.1c  | Add TradesController with new, create, index actions                    | +8    |
| 40  | 11.1d  | Add trade form view with Turbo Frame modal                              | +6    |
| 41  | 11.1e  | Add position locking and edge case handling                             | +6    |
| 42  | 11.1f  | Add system test for full trade flow                                     | +4    |
| 43  | 11.2a  | Add historical Fear & Greed SVG chart on dashboard                      | +5    |
| 44  | 11.2b  | Add news watchlist filter                                               | +5    |
| 45  | 11.2c  | Add earnings watchlist filter                                           | +5    |
| 46  | 11.3a  | Add fetch_earnings method to PolygonGateway                             | +4    |
| 47  | 11.3b  | Add earnings sync pipeline with SyncCalendar use case                   | +8    |
| 48  | 11.3c  | Register earnings sync in DataSourceRegistry and recurring schedule     | +3    |
| 49  | 12.0a  | Add email_verified_at to users                                          | +3    |
| 50  | 12.0b  | Add VerifyEmail use case and contract                                   | +6    |
| 51  | 12.0c  | Add verification email handler and mailer method                        | +4    |
| 52  | 12.0d  | Add EmailVerificationsController and verification page                  | +4    |
| 53  | 12.0e  | Add unverified email banner in app layout                               | +3    |
| 54  | 12.1a  | Add alert management system test                                        | +6    |
| 55  | 12.1b  | Add watchlist management system test                                    | +5    |
| 56  | 12.1c  | Add portfolio tabs system test                                          | +5    |
| 57  | 12.1d  | Add earnings calendar system test                                       | +4    |
| 58  | 12.1e  | Add admin management system test                                        | +5    |
| 59  | 12.1f  | Add password reset flow system test                                     | +5    |
| 60  | 12.2a  | Add WeeklyInsightCalculator domain service                              | +6    |
| 61  | 12.2b  | Enable weekly insight with real portfolio data                          | +4    |
| 62  | 12.2c  | Add Trivy scanning to CI, remove disabled button states                 | +3    |
| 63  | 12.2d  | Add Bullet gem, fix N+1 queries                                        | +2    |
| 64  | 13.0a  | Add sentiment conditions to AlertRule enum                              | +2    |
| 65  | 13.0b  | Extend AlertEvaluator with sentiment conditions                         | +6    |
| 66  | 13.0c  | Add EvaluateSentimentAlerts handler on FearGreedUpdated                  | +4    |
| 67  | 13.0d  | Add sentiment options to alert form                                     | +3    |
| 68  | 13.1a  | Add BanxicoGateway for CETES auction results                           | +6    |
| 69  | 13.1b  | Add YieldCalculator domain service                                      | +6    |
| 70  | 13.1c  | Add SyncCetesJob with events and handler                                | +5    |
| 71  | 13.1d  | Add fixed income detail view and maturity calendar                      | +5    |
| 72  | 13.1e  | Add CETES detail page system test                                       | +3    |
| 73  | 13.2a  | Add missing database indexes, fix N+1 queries                           | +4    |
| 74  | 13.2b  | Add fragment caching and Russian doll caching                           | +6    |
| 75  | 13.2c  | Add volume alerts with cooldown period                                  | +6    |
| 76  | 13.2d  | Add historical P/E chart component                                      | +4    |

### Phase 14 (Completed — 13 commits)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
| 77  | 14.0a  | Fix portfolio empty state with always-visible trade form                | +4    |
| 78  | 14.0b+e | Connect search to backend with keyboard navigation                     | +8    |
| 79  | 14.0c  | Make market listing rows fully clickable with hover UX                  | +3    |
| 80  | 14.0d  | Add asset detail price chart (SVG area chart)                           | +6    |
| 81  | 14.2a  | Extend earnings sync with actual_eps and beat/miss calculation          | +9    |
| 82  | 14.2b  | Add beat/miss badges to earnings calendar                               | +4    |
| 83  | 14.2c+d | Add earnings detail page with show route and system test               | +9    |
| 84  | 14.3a  | Add UpdateTrade use case with 30-day edit guard                         | +20   |
| 85  | 14.3b  | Add DeleteTrade use case with soft delete via discarded_at              | +15   |
| 86  | 14.3c  | Add trade edit/delete UI with inline editing and soft delete            | +12   |
| 87  | 14.4a  | Add PeriodReturnsCalculator for portfolio time-based returns            | +7    |
| 88  | 14.4b  | Add portfolio performance chart with period return pills               | +5    |
| 89  | 14.4c  | Add earnings approaching alerts with daily notification job             | +8    |
|     |        | *Phase 14 Total*                                                        | *+110* |
|     |        | **Grand Total (Phases 9-14)**                                           | **~523** |

### Phase 15 (Completed — 20 commits)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
| 90  | 15.0a  | Add expandable error details to admin logs table                        | +4    |
| 91  | 15.0b  | Add sync_issue_since field and RetryFailedAssetsJob with auto-recovery  | +10   |
| 92  | 15.0c  | Add backfill rake tasks for prices, earnings, and fundamentals          | +6    |
| 93  | 15.0d  | Add daily API call budget tracking per Integration                      | +5    |
| 94  | 15.1a  | Consolidate F&G cards with inline sparklines, remove chart row          | +4    |
| 95  | 15.1b  | Add interactive tooltips to F&G and price charts                        | +4    |
| 96  | 15.1c  | Redesign news cards as compact feed lines                               | +3    |
| 97  | 15.2a  | Add adaptive sync scheduling with backoff on rate limits                | +6    |
| 98  | 15.2b  | Add gateway fallback chain for market indices                           | +4    |
| 99  | 15.2c  | Add on-demand fundamental sync from asset detail page                   | +5    |
| 100 | 15.3a  | Batch Yahoo Finance index queries via quote endpoint                    | +5    |
| 101 | 15.3b  | Unify crypto sync jobs and increase interval to 5 minutes               | +3    |
| 102 | 15.3c  | Add bulk stock price sync via Polygon grouped endpoint                  | +6    |
| 103 | 15.3d  | Reduce Alpha Vantage frequency to bi-weekly overview                    | +3    |
| 104 | 15.4a  | Increase earnings sync to daily with 90-day window                      | +4    |
| 105 | 15.4b  | Add BackfillMissingHistoriesJob as weekly recurring job                  | +4    |
| 106 | 15.4c  | Add integration tests for full backfill flows                           | +6    |
| 107 | 15.4d  | Add /health endpoint with sync freshness and admin status dashboard     | +5    |
| 108 | 15.5a  | Add API key rotation pool for providers                                 | +5    |
| 109 | 15.5b  | Add TradingView Advanced Chart widget to asset detail page              | +4    |
|     |        | *Phase 15 Total*                                                        | *+96* |

### Phase 15.6 (Completed — 7 commits)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
| 110 | 15.6a  | Add name to ApiKeyPool and rate limit fields to Integration             | +8    |
| 111 | 15.6b  | Add RateLimiter domain service with per-minute and per-day checks       | +10   |
| 112 | 15.6c  | Integrate RateLimiter into gateways                                     | +8    |
| 113 | 15.6d  | Add UpdateProvider and DeleteProvider use cases                          | +14   |
| 114 | 15.6e  | Add AddPoolKey, TogglePoolKey, and RemovePoolKey use cases              | +12   |
| 115 | 15.6f  | Add admin API key pool controller and routes                            | +10   |
| 116 | 15.6g  | Redesign admin integrations UI with pool management                     | +8    |
|     |        | *Phase 15.6 Total*                                                      | *+70* |
|     |        | **Grand Total (Phases 9-15.6)**                                         | **~689** |

---

## Upcoming Phases (16-21)

> **Objetivo:** Production hardening, financial domain depth, UX maturity
> **Note:** Phase 17 from the original v2 plan was completed early as Phase 15.6 (Rate Limits & Admin). Phases renumbered accordingly.

---

## Phase 16 — Production Hardening & Security

> **Theme:** "Make it safe before making it bigger"
> **Owner:** DevOps Engineer + Security Engineer
> **Estimated specs:** ~38

### 16.0 — Critical Security Fixes

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 117 | Remove `.env.production` from repo, add to `.gitignore` | Security — rotate all exposed keys | +0 |
| 118 | Add session timeout (30-min inactivity, 12-hour absolute) | Security — `config/initializers/session_store.rb` | +4 |
| 119 | Add Rack::Attack for endpoint rate limiting | Security — login (5/min), register (3/min), password reset (3/min) | +8 |

**Security Engineer rationale:**
> `.env.production` contains live `SECRET_KEY_BASE`, `DATABASE_URL`, 6 API keys, and host IP — all must be rotated immediately. Session timeout is table-stakes for fintech: an unattended session is a liability. Rack::Attack prevents brute-force at the HTTP layer (separate from the provider-level `RateLimiter` in Phase 15.6).

### 16.1 — PostgreSQL Backups

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 120 | Add pg_dump backup rake task with S3 upload | `lib/tasks/backup.rake`, env config | +4 |
| 121 | Add Kamal backup accessory with daily cron | `config/deploy.yml`, restore documentation | +2 |

**DevOps Engineer rationale:**
> Financial data without backups = existential risk. pg_dump daily to S3-compatible storage (Backblaze B2 is $5/mo for 1TB). WAL archiving is overkill for current scale — daily logical backups suffice. Restore procedure must be documented and tested.

### 16.2 — Audit & Observability

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 122 | Add audit logging for login attempts and password changes | Event handlers, AuditLog expansion | +6 |
| 123 | Add IDOR controller-level tests for watchlist, alerts, notifications | Test-only commit — no app changes | +12 |
| 124 | Add structured JSON logging for production | `config/environments/production.rb`, log formatter | +2 |

**QA Engineer rationale:**
> Authorization is enforced at the Use Case layer (good), but no tests verify this at the controller layer. We need explicit specs: "User A cannot access User B's alerts/watchlist/notifications." Also, failed login tracking enables brute-force detection and compliance audit trails.

**Phase 16 Total: ~38 specs, ~8 commits**

---

## Phase 17 — Financial Domain Depth

> **Theme:** "Make the numbers trustworthy"
> **Owner:** Financial Expert + Domain Architect + Rails Engineer
> **Estimated specs:** ~70

### 17.0 — Trade Export (CSV/PDF)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 125 | Add Trading::ExportTrades use case with CSV generation | Use case, contract, CSV builder | +8 |
| 126 | Add PDF trade report with Prawn | `Prawn` gem, PDF template, download action | +4 |
| 127 | Add export UI on portfolio page with format selection | Views, controller action, system test | +4 |

**Product Strategist rationale:**
> In Mexico, SAT annual tax declaration requires trade history. Every user who files taxes needs this. April is tax season — shipping this before then = high retention. CSV is trivial, PDF with Prawn adds polish.

### 17.1 — Portfolio Benchmarking (TWR)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 128 | Add MarketIndexHistory model with daily close prices | Migration, model, backfill job | +6 |
| 129 | Add TimeWeightedReturn domain service (TWR calculator) | Domain service — pure math, no AR | +10 |
| 130 | Add benchmark selection to portfolio and comparison UI | Controller, views, Stimulus chart | +6 |
| 131 | Add benchmark sync job for S&P 500 via Yahoo Finance | Job, gateway extension, schedule | +4 |

**Financial Expert rationale:**
> TWR is the industry standard for measuring portfolio manager skill because it eliminates the effect of cash flows (deposits/withdrawals). Formula: TWR = ∏(1 + R_i) - 1, where R_i = (V_end - V_start - CF) / V_start per sub-period. We already have `PortfolioSnapshot` — TWR can use these directly.

**Domain Architect rationale:**
> `TimeWeightedReturn` lives in `app/domain/` as a pure Domain Service. Input: array of snapshots + cash flow events. Output: `GainLoss` value object. No ActiveRecord dependency — fully testable with synthetic data.

### 17.2 — Dividend Sync & Tracking

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 132 | Add FmpGateway for dividend and split data | New gateway, circuit breaker, specs | +6 |
| 133 | Add SyncDividendsJob with event pipeline | Job, events, handlers | +6 |
| 134 | Add upcoming dividends view on portfolio page | Views, presenter, system test | +4 |
| 135 | Add stock split handling with cost basis adjustment | Domain service, position recalculation | +8 |

**Data Engineer rationale:**
> FMP (Financial Modeling Prep) free tier: 250 calls/day, includes dividends and splits. The Gateway abstraction makes adding a new provider clean. Splits are critical: without split-adjusted cost basis, P&L becomes nonsensical after a 2:1 split.

### 17.3 — Position Notes & Labels (Quick Win)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 136 | Add notes and labels to positions | Migration, model, form field, display | +4 |

**Phase 17 Total: ~70 specs, ~12 commits**

---

## Phase 18 — UX Maturity

> **Theme:** "Look and feel like a real product"
> **Owner:** UX Designer + Hotwire Engineer
> **Estimated specs:** ~42

### 18.0 — Accessibility (WCAG 2.1 AA)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 137 | Add skip-to-content link and ARIA landmarks to layouts | Layouts, semantic HTML | +3 |
| 138 | Add aria-describedby to form error messages and aria-live to dynamic regions | Forms, Turbo Streams | +4 |
| 139 | Add keyboard navigation to modals and focus trapping | Stimulus controllers | +4 |

### 18.1 — Loading States & Skeleton Screens

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 140 | Add skeleton loader component and Turbo Frame loading states | Component partial, CSS animations | +3 |
| 141 | Add loading states to dashboard, market, and portfolio pages | Views, `busy` attribute on frames | +4 |

### 18.2 — Dark Mode Toggle

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 142 | Add dark mode toggle to navbar with localStorage persistence | Stimulus controller, layout, CSS | +3 |

### 18.3 — Internationalization Foundation (i18n)

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 143 | Add Spanish locale file and extract critical UI strings | `config/locales/es.yml`, nav, buttons, labels | +4 |
| 144 | Add language switcher to profile settings | Controller, session locale, middleware | +3 |

### 18.4 — Bulk CSV Import

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 145 | Add Trading::ImportTrades use case with CSV parsing and sanitization | Use case, contract, sanitizer | +10 |
| 146 | Add CSV import UI on portfolio page with drag-and-drop | Views, Stimulus controller, system test | +4 |

**Security Engineer rationale:**
> CSV formula injection is real: cells starting with `=`, `+`, `-`, `@` can execute arbitrary commands when opened in Excel. The sanitizer must strip these prefixes. Max 500 rows per import, with dry-run preview before committing.

**Phase 18 Total: ~42 specs, ~10 commits**

---

## Phase 19 — Advanced Analytics & Risk

> **Theme:** "From tracking to insights"
> **Owner:** Financial Expert + Domain Architect
> **Estimated specs:** ~48

### 19.0 — Risk Metrics

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 147 | Add PortfolioRiskCalculator domain service (volatility, Sharpe, max drawdown) | Domain service — pure math | +10 |
| 148 | Add risk metrics display on portfolio page | Views, presenter, Turbo Frame | +4 |

**Financial Expert rationale:**
> Returns without risk context are meaningless. Three metrics cover 80% of the need:
> - **Volatility (σ):** Standard deviation of daily returns
> - **Sharpe Ratio:** (Return - Risk-Free Rate) / σ
> - **Max Drawdown:** Largest peak-to-trough decline
>
> All calculable from existing `PortfolioSnapshot` data. No new data sources needed.

### 19.1 — Concentration Alerts

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 149 | Add concentration_risk condition to AlertRule | Migration, AlertEvaluator extension | +6 |
| 150 | Add portfolio concentration warnings on dashboard | Views, domain service | +4 |

### 19.2 — Advanced Composite Alerts

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 151 | Add AND/OR predicate composition to AlertRule | Migration, evaluator refactor | +8 |
| 152 | Add composite alert builder UI | Views, Stimulus, system test | +6 |

### 19.3 — Sector Comparison

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 153 | Add sector aggregation to portfolio analytics | Domain service, presenter | +6 |
| 154 | Add sector breakdown chart on portfolio page | Views, donut chart extension | +4 |

**Phase 19 Total: ~48 specs, ~8 commits**

---

## Phase 20 — Provider Upgrade & Data Quality

> **Theme:** "Better data, fewer limits"
> **Owner:** Data Engineer + DevOps Engineer
> **Estimated specs:** ~22

### 20.0 — FMP Provider Integration

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 155 | Add FmpGateway with company profile and fundamentals | Gateway, circuit breaker, specs | +6 |
| 156 | Add FMP as fallback in GatewayChain for fundamentals | Chain config, adaptive scheduling | +4 |

### 20.1 — PWA Support

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 157 | Add PWA manifest and service worker for installability | `public/manifest.json`, service worker, icons | +3 |
| 158 | Add offline fallback page and cache strategy | Service worker cache, offline view | +3 |

### 20.2 — Error Tracking & Monitoring

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 159 | Add Sentry integration for error tracking | Gem, initializer, production config | +2 |
| 160 | Add health dashboard improvements (job queue depth, cache hit rate) | Admin view, domain service | +4 |

**Phase 20 Total: ~22 specs, ~6 commits**

---

## Phase 21 — LLM-Powered Intelligence Layer

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

### 21.0 — Stockerly LLM Gateway

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 161 | Add LlmGateway with Faraday client to SheLLM | Gateway, CircuitBreaker, RateLimiter integration | +8 |
| 162 | Add SheLLM Integration seed and admin health indicator | Seeds, admin view, health check | +4 |
| 163 | Add LlmResponseContract for output validation | Contract, Dry::Validation, JSON schema enforcement | +6 |

### 21.1 — Portfolio Insight Generator

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 164 | Add InsightGenerator domain service with analysis prompt | Domain service, system prompt template, anonymizer | +8 |
| 165 | Add GeneratePortfolioInsightsJob as daily recurring job | Job (11:15pm after snapshots), events, handlers | +6 |
| 166 | Add AI insight card to dashboard with attribution label | Views, Turbo Frame, opt-out toggle, "AI-generated" label | +4 |

### 21.2 — News Sentiment Analysis

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 167 | Add NewsSentimentAnalyzer domain service with batch processing | Domain service, batch prompt (10 articles per call) | +8 |
| 168 | Add AnalyzeNewsSentimentJob triggered after news sync | Job, event handler, migration (sentiment columns on news_articles) | +6 |
| 169 | Add sentiment badges and filter to news feed | Views, filter, Turbo Frame update | +4 |

### 21.3 — Fundamental Health Checks

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 170 | Add FundamentalHealthCheck domain service | Domain service, prompt template, 7-day cache | +6 |
| 171 | Add AI health check section to asset detail page | Views, Turbo Frame, cache integration | +4 |

### 21.4 — Earnings Narrative

| # | Commit | Scope | Specs |
|---|--------|-------|-------|
| 172 | Add EarningsNarrativeGenerator for earnings detail page | Domain service, views, cache | +5 |

**Phase 21 Total: ~65 specs, ~12 commits**

---

## Summary & Sequencing

### Phase Dependency Graph

```
Phase 16 (Security) ──────────────────► Production-ready
    │
Phase 17 (Financial Domain) ─────────► User value (export, benchmarking, dividends)
    │
Phase 18 (UX Maturity) ──────────────► Polish (a11y, i18n, loading states, CSV import)
    │
Phase 19 (Advanced Analytics) ───────► Differentiation (risk metrics, composite alerts)
    │
Phase 20 (Provider Upgrade) ─────────► Scale (FMP, PWA, monitoring)
    │
Phase 21 (LLM Intelligence) ─────────► AI insights (requires SheLLM deployed)
    ▲
    │ External dependency: SheLLM (separate repo)
    │ See SHELLM_PLAN.md
```

### Totals

| Phase | Theme | Commits | Estimated Specs | Running Total |
|-------|-------|---------|-----------------|---------------|
| 16 | Production Hardening | 8 | ~38 | ~1735 |
| 17 | Financial Domain | 12 | ~70 | ~1805 |
| 18 | UX Maturity | 10 | ~42 | ~1847 |
| 19 | Advanced Analytics | 8 | ~48 | ~1895 |
| 20 | Provider Upgrade | 6 | ~22 | ~1917 |
| 21 | LLM Intelligence | 12 | ~65 | ~1982 |
| | **Total Upcoming** | **~56** | **~285** | **~1982** |

### External Dependencies

| Dependency | Repository | Status | Required By |
|---|---|---|---|
| **SheLLM** | `shellm` | Plan ready (`SHELLM_PLAN.md`) | Phase 21 |

---

## Deferred to v3+

| Feature | Reason | Expert |
|---------|--------|--------|
| **Tax Lot Tracking (FIFO/LIFO)** | Complex, requires cost lot model + tax regime selection. Do after trade export validates demand. | Financial Expert |
| **Profile Sharing / Privacy Mode** | No community features yet. Zero demand signal. | Domain Architect |
| **Full i18n (all views)** | v2 does critical strings only. Full extraction is mechanical but large. | Hotwire Engineer |
| **Performance Attribution by Position** | Requires position-level snapshots (expensive storage). After TWR proves value. | Financial Expert |
| **Wash Sale Detection** | US-specific tax rule. Not relevant for Mexican market. | Financial Expert |
| **Options/Warrants Tracking** | Entirely different asset class with Greeks, chains, expiry. Separate product. | Domain Architect |
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
- Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
