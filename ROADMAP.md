# Stockerly — Roadmap

> **Fecha:** 2026-02-25
> **Estado actual:** 1627 specs, 93.6% line coverage, Phase 15 complete
> **Siguiente:** v2 features (see Explicitly Deferred)

---

## Completed Phases (0-15) — 1627 specs

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

---

## All Phases Complete

All planned phases (0-15) are complete. 1627 specs, 93.6% line coverage.
See "Explicitly Deferred" section below for v2+ features.

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
|     |        | **Grand Total (Phases 9-15)**                                           | **~619** |

---

## Explicitly Deferred (v2+)

| Feature | Reason for Deferral | Expert |
|---------|-------------------|--------|
| **Profile Sharing / Privacy Mode** | Requires new authorization model, no community features yet | Domain Architect |
| **Portfolio Benchmarking (TWR)** | Requires `MarketIndexHistory` model + TWR calculation (non-trivial) | Financial Expert |
| **Sector Comparison** | Needs sector-level aggregation data source | Data Engineer |
| **FMP/Polygon Provider Swap** | Upgrade from Alpha Vantage when budget allows (abstraction ready) | Data Engineer |
| **Advanced Composite Alerts** | Requires predicate composition engine refactor | Domain Architect |
| **BulkAssetSync Concern** | DRY refactor of bulk sync jobs — low urgency, already working | Rails Backend |
| **Bulk CSV Import** | Input sanitization critical (formula injection vector), max 500 rows | Security Engineer |
| **Trade Export (CSV/PDF)** | Low reach, nice-to-have | Product Strategist |
| **Position Notes/Labels** | Low impact, low effort — backlog filler | UX Designer |
| **Dividend Sync (External)** | Polygon charges for corporate actions data | Financial Expert |
| **Tax Lot Tracking (FIFO/LIFO)** | Complex, low demand for retail audience | Financial Expert |
| **Performance Attribution by Sector** | Needs sector-level aggregation | Data Engineer |
| **SSL End-to-End** | Kamal proxy SSL + Cloudflare Full Strict or Tunnel | DevOps |
| **PostgreSQL Backups** | pg_dump daily to S3, WAL archiving, monitoring | DevOps |

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
