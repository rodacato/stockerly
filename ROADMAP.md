# Stockerly — Roadmap

> **Fecha:** 2026-02-25
> **Estado actual:** 1415 specs, 95.4% line coverage, Phase 13 complete
> **Siguiente:** Phase 14 (TBD)

---

## Completed Phases (0-10) — 1216 specs

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

### Phase 9 Summary (990 specs, 20 commits)

**Infrastructure:** DataSourceRegistry (EventBus pattern), SyncLogging concern, `Integration.requires_api_key`, dynamic admin panel. **Data:** Fear & Greed from Alternative.me + CNN, historical prices from Polygon + CoinGecko, news from Polygon, market indices from Yahoo Finance, CETES placeholder schema. **Key patterns:** Circuit breaker per source, event-driven backfill (`AssetCreated` → `BackfillPriceHistoryJob`), sparkline normalization helper.

### Phase 10 Summary (1216 specs, 12 commits)

**Models:** `FinancialStatement` (JSONB), `AssetFundamental` (JSONB metrics), 33 `MetricDefinitions` (Data.define). **Gateways:** `AlphaVantageGateway` (OVERVIEW + 3 statement endpoints, "Note" key rate limit detection), `CoingeckoGateway#fetch_market_data` (extended crypto data). **Domain:** `FundamentalCalculator` (D/E, TTM, CAGR, all formulas), `FundamentalPresenter` (live P/E, P/B, P/S at render). **UI:** Asset detail page (`/market/:symbol`) with 7 stock tabs + 2 crypto tabs, adaptive rendering, educational tooltips, regulatory disclaimer. **Events:** `FinancialStatementsSynced` → recalculate → `AssetFundamentalsUpdated` → Turbo broadcast.

### Key Architecture Decisions (from Phase 9-10)

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

### Source Plans (for historical reference)

- `PLAN_SENTIMENT.md` — Phase 9.0-9.1 architecture
- `PLAN_IMPROVEMENTS.md` — Phase 9.2-9.5 features
- `PLAN_METRICS.md` — Phase 10.0-10.3 fundamentals

---

## Pending Phases — Summary

| Fase     | Nombre                          | Tipo      | Est. Specs | Acumulado |
| -------- | ------------------------------- | --------- | ---------- | --------- |
| **11.0** | TrendScore Real Data            | Pendiente | ~20        | ~1236     |
| **11.1** | Trade Entry UI                  | Pendiente | ~40        | ~1276     |
| **11.2** | Quick Wins (F&G Chart, Filters) | Pendiente | ~15        | ~1291     |
| **11.3** | Earnings External API           | Pendiente | ~15        | ~1306     |
|          | *Phase 11 Total*                |           | *~90*      |           |
| **12.0** | Email Verification              | Pendiente | ~20        | ~1326     |
| **12.1** | System Test Expansion           | Pendiente | ~30        | ~1356     |
| **12.2** | Weekly Insight + CI Hardening   | Pendiente | ~15        | ~1371     |
|          | *Phase 12 Total*                |           | *~65*      |           |
| **13.0** | Sentiment-based Alerts          | Pendiente | ~15        | ~1386     |
| **13.1** | CETES Complete                  | Pendiente | ~25        | ~1411     |
| **13.2** | Performance + Advanced Alerts   | Pendiente | ~20        | ~1431     |
|          | *Phase 13 Total*                |           | *~60*      |           |
|          | **Grand Total New**             |           | **~215**   | **~1431** |

---

## Expert Panel Consensus

> **Panel:** 10 expert profiles from `docs/spec/EXPERTS.md`
> **Method:** Each expert proposed top 3 priorities → debate → consensus ranking

### Expert Vote Summary

| Feature | Votes (of 10) | Phase |
|---------|---------------|-------|
| Trade Entry UI | 8 | 11.1 |
| TrendScore Real Data | 6 | 11.0 |
| SSL + Backups | 5 | Pre-11 |
| Email Verification | 4 | 12.0 |
| Historical F&G Chart | 4 | 11.2 |
| System Test Expansion | 3 | 12.1 |
| Earnings External API | 3 | 11.3 |
| CETES Complete | 2 | 13.1 |
| Sentiment Alerts | 2 | 13.0 |
| Performance Audit | 2 | 13.2 |

### Key Debates (Resolved)

1. **TrendScore vs Trade Entry first?** → TrendScore first (11.0): smaller scope, highest data integrity impact, no UI changes. Trade Entry follows (11.1).
2. **SSL/Backups timing?** → Pre-Phase 11 infrastructure (parallel). Existential for fintech.
3. **Email Verification priority?** → Phase 12 (soft block with banner, not hard redirect).
4. **Quick wins grouping?** → F&G Chart + Watchlist Filters bundled in 11.2 (low effort, high visibility).
5. **CETES timing?** → Phase 13. Requires new gateway (Banxico) + yield calculations.

---

## Pre-Phase 11 — Infrastructure Hardening

> **Type:** Infrastructure only (no application code, 0 specs)
> **Can be done in parallel with Phase 11**

| # | Item | Description | Owner |
|---|------|-------------|-------|
| S-1 | **SSL End-to-End** | Kamal proxy SSL + Cloudflare Full Strict or Tunnel | DevOps |
| S-2 | **PostgreSQL Backups** | pg_dump daily to S3, WAL archiving, monitoring | DevOps |

---

## Phase 11 — Core Loop Completion + Data Integrity (~90 specs)

> **Goal:** Complete the primary user loop (view portfolio → log trade → see updated P&L) and replace all fabricated data with real computed values.
> **Depends on:** Phase 10 complete
> **Estimated accumulated specs:** ~1306

### Phase 11.0 — TrendScore Real Data (~20 specs)

**Why first:** Smallest scope, highest data integrity impact, no UI changes needed.

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 11.0a | `TrendScoreCalculator` domain service — RSI-14 + 7-day momentum from `AssetPriceHistory` | New: `app/domain/trend_score_calculator.rb` | +8 |
| 11.0b | `RecalculateTrendScoreOnPriceUpdate` event handler (async, triggered by `AssetPriceUpdated`) | New handler, Modify: `config/initializers/event_subscriptions.rb` | +4 |
| 11.0c | `CalculateTrendScoresJob` for bulk backfill | New: `app/jobs/calculate_trend_scores_job.rb`, Modify: `config/recurring.yml` | +4 |
| 11.0d | Remove hardcoded trend score seeds, update `MarketSentiment` fallbacks | Modify: `db/seeds.rb`, `app/domain/market_sentiment.rb` | +4 |

**Key architecture decisions:**
- `TrendScoreCalculator` is a pure domain service (like `FundamentalCalculator`) — no DB reads, receives array of closes, returns `{ score:, label:, direction: }`
- RSI-14 formula: `100 - (100 / (1 + avg_gain / avg_loss))` over 14 periods
- Momentum: `(current_close - close_7d_ago) / close_7d_ago * 100`
- Score blending: `0.6 * normalized_rsi + 0.4 * normalized_momentum`
- Event handler is `async? = true` to avoid blocking price sync pipeline

### Phase 11.1 — Trade Entry UI (~40 specs)

**Why second:** Core user loop — the most impactful user-facing feature (8/10 expert votes).

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 11.1a | `Trades::ExecuteTradeContract` (dry-validation) | New: `app/contracts/trades/execute_trade_contract.rb` | +6 |
| 11.1b | `Trades::ExecuteTrade` use case with position handling | New: `app/use_cases/trades/execute_trade.rb` | +10 |
| 11.1c | `TradesController` (new, create, index) | New: `app/controllers/trades_controller.rb`, Modify: `config/routes.rb` | +8 |
| 11.1d | Trade form view (Turbo Frame modal) + trade history tab | New: `app/views/trades/`, Modify: `app/views/portfolios/_positions_table.html.erb` | +6 |
| 11.1e | Position locking + edge cases (sell all = close, new buy = create position) | Modify: `app/event_handlers/recalculate_avg_cost_on_trade.rb` | +6 |
| 11.1f | System test: full trade flow (buy, verify position updated, sell, verify closed) | New: `spec/system/trade_flow_spec.rb` | +4 |

**Key architecture decisions:**
- Use case creates `Trade`, then publishes `TradeExecuted` (existing event)
- Handler `RecalculateAvgCostOnTrade` already exists — add `with_lock` for concurrency safety
- If user buys an asset with no open position, use case creates a new `Position` (status: open)
- If user sells all shares, use case closes the position (status: closed)
- Contract validates: `shares > 0`, `price_per_share > 0`, `side in %w[buy sell]`, `asset_symbol present`
- The `executed_at` field defaults to `Time.current` but can be set to past dates for manual entry

### Phase 11.2 — Quick Wins: F&G Chart + News Watchlist Filter (~15 specs)

**Why third:** Low effort, high visibility. Ships in same phase as the bigger features.

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 11.2a | Historical F&G Chart — SVG line chart below F&G cards on dashboard | New: `app/views/dashboard/_fear_greed_chart.html.erb`, Modify: `app/views/dashboard/show.html.erb`, `app/use_cases/dashboard/assemble.rb` | +5 |
| 11.2b | News Watchlist Filter — filter pill + query scope | Modify: `app/use_cases/news/list_articles.rb`, `app/views/news/index.html.erb` | +5 |
| 11.2c | Earnings Watchlist Filter — `Watchlist Only` filter on earnings calendar | Modify: `app/use_cases/earnings/list_for_month.rb`, `app/views/earnings/index.html.erb` | +5 |

**Key architecture decisions:**
- F&G chart uses pure SVG `<polyline>` with color-banded background rectangles (no JS library)
- Data from `FearGreedReading.crypto.recent` (already scoped to last 30 records)
- News watchlist filter adds `.where(related_ticker: symbols)` to existing query chain
- No new models, no new jobs, no new events

### Phase 11.3 — Earnings External API (~15 specs)

**Why fourth:** Replaces the last major set of seeded data.

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 11.3a | `PolygonGateway#fetch_earnings(ticker)` method | Modify: `app/gateways/polygon_gateway.rb` | +4 |
| 11.3b | `Earnings::SyncCalendar` use case + `SyncEarningsJob` | New: use case, job, event, handler | +8 |
| 11.3c | Register in DataSourceRegistry + recurring schedule | Modify: `config/initializers/data_sources.rb`, `config/recurring.yml` | +3 |

**Key architecture decisions:**
- Polygon endpoint: `GET /vX/reference/tickers/{ticker}/earnings`
- Upserts by `[asset_id, report_date]` (unique constraint already exists on `EarningsEvent`)
- Syncs weekly (Sundays 9am) for all watchlisted/portfolio assets
- Publishes `EarningsSynced` event for logging

---

## Phase 12 — Security, Quality, and Polish (~65 specs)

> **Goal:** Harden security, expand test coverage, enable disabled UI buttons.
> **Depends on:** Phase 11 complete
> **Estimated accumulated specs:** ~1371

### Phase 12.0 — Email Verification (~20 specs)

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 12.0a | Migration: `add_email_verified_at_to_users` | New migration, Modify: `app/models/user.rb` | +3 |
| 12.0b | `Identity::VerifyEmail` use case + contract | New: use case + contract | +6 |
| 12.0c | `SendVerificationEmailOnRegistration` event handler + `UserMailer#verify_email` | New handler, Modify: `app/mailers/user_mailer.rb` | +4 |
| 12.0d | `EmailVerificationsController` + verification page | New controller + views | +4 |
| 12.0e | Persistent banner for unverified users in app layout | Modify: `app/views/layouts/app.html.erb` | +3 |

**Key decisions:** Soft block (banner, not redirect). Unverified users can use the platform but see a persistent "Verify your email" banner. This avoids breaking the onboarding flow.

### Phase 12.1 — System Test Expansion (~30 specs)

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 12.1a | Alert management flow (create, edit, toggle, delete) | New: `spec/system/alerts_spec.rb` | +6 |
| 12.1b | Watchlist management (add from market, remove from profile) | New: `spec/system/watchlist_spec.rb` | +5 |
| 12.1c | Portfolio tabs (open, closed, dividends, trade log) | New: `spec/system/portfolio_spec.rb` | +5 |
| 12.1d | Earnings calendar navigation | New: `spec/system/earnings_spec.rb` | +4 |
| 12.1e | Admin asset management + sync | New: `spec/system/admin_spec.rb` | +5 |
| 12.1f | Password reset flow | New: `spec/system/password_reset_spec.rb` | +5 |

### Phase 12.2 — Weekly Insight (Real Data) + CI Hardening (~15 specs)

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 12.2a | `WeeklyInsightCalculator` domain service | New: `app/domain/weekly_insight_calculator.rb` | +6 |
| 12.2b | Enable "View Full Report" button, render real insights | Modify: dashboard views + `app/use_cases/dashboard/assemble.rb` | +4 |
| 12.2c | Docker image scanning (Trivy) in CI + remove disabled button states | Modify: `.github/workflows/ci.yml`, affected views | +3 |
| 12.2d | Performance audit: Bullet gem, index verification, N+1 fixes | Modify: `Gemfile`, affected queries | +2 |

**Key decisions for Weekly Insight:**
- Language is strictly observational: "Your portfolio was up X% this week. Top performer: AAPL (+Y%)."
- No imperative advice. No "Consider diversifying" or "You should buy".
- Disclaimer footer from Phase 10.2 is reused.
- Data source: `PortfolioSnapshot` (7-day window), open positions with price changes.

---

## Phase 13 — Market Expansion + Advanced Features (~60 specs)

> **Goal:** Niche differentiators and advanced user features.
> **Depends on:** Phase 12 complete
> **Estimated accumulated specs:** ~1431

### Phase 13.0 — Sentiment-based Alerts (~15 specs)

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 13.0a | Add `sentiment_above` and `sentiment_below` to `AlertRule.condition` enum | Modify: `app/models/alert_rule.rb` | +2 |
| 13.0b | Extend `AlertEvaluator` with sentiment conditions | Modify: `app/domain/alert_evaluator.rb` | +6 |
| 13.0c | `EvaluateSentimentAlerts` handler on `FearGreedUpdated` | New handler, Modify: event subscriptions | +4 |
| 13.0d | Update alert form with sentiment condition options | Modify: alert views | +3 |

### Phase 13.1 — CETES Complete (~25 specs)

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 13.1a | `BanxicoGateway` — fetch CETES auction results | New: `app/gateways/banxico_gateway.rb` | +6 |
| 13.1b | `YieldCalculator` domain service (discount rate, yield to maturity) | New: `app/domain/yield_calculator.rb` | +6 |
| 13.1c | `SyncCetesJob` + events + handler | New job + event + handler | +5 |
| 13.1d | Fixed income detail view + maturity calendar | New views in `/market/` | +5 |
| 13.1e | System test: CETES detail page | New: `spec/system/cetes_spec.rb` | +3 |

### Phase 13.2 — Performance + Advanced Alerts (~20 specs)

| Step | Description | Files | Specs |
|------|-------------|-------|-------|
| 13.2a | Performance audit results: add missing indexes, fix N+1 queries | Migrations + model modifications | +4 |
| 13.2b | Caching strategy: fragment caching for dashboard, Russian doll for tables | Modify: views + controllers | +6 |
| 13.2c | Volume alerts + cooldown period on AlertRule | Migration + `AlertEvaluator` extension | +6 |
| 13.2d | Historical P/E chart (requires charting library decision) | New: chart component | +4 |

---

## Commit Sequence

### Phases 9-10 (Completed — 32 commits)

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

### Phase 11 (Pending)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
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
| 47  | 11.3b  | Add SyncEarningsJob with Polygon earnings integration                   | +8    |
| 48  | 11.3c  | Register earnings sync in DataSourceRegistry                            | +3    |
|     |        | *Phase 11 Total*                                                        | *~90* |

### Phase 12 (Pending)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
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
|     |        | *Phase 12 Total*                                                        | *~65* |

### Phase 13 (Complete — 1415 specs)

| #   | Phase  | Commit Message                                                          | Specs |
| --- | ------ | ----------------------------------------------------------------------- | ----- |
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
|     |        | *Phase 13 Total*                                                        | *~60* |
|     |        | **Grand Total (Phases 9-13)**                                           | **~403** |

---

## Dependency Graph

```
Pre-Phase 11 (Infrastructure) ──── parallel with everything

Phase 11 (Core Loop + Data Integrity)
  ├── 11.0 TrendScore ────────── independent
  ├── 11.1 Trade Entry ───────── independent
  ├── 11.2 Quick Wins ────────── independent (F&G chart needs dashboard data)
  └── 11.3 Earnings API ──────── independent (uses PolygonGateway)

Phase 12 (Security + Quality) ── depends on Phase 11
  ├── 12.0 Email Verification ── independent
  ├── 12.1 System Tests ──────── depends on 11.1 (needs Trade flow to test)
  └── 12.2 Weekly Insight + CI ─ independent

Phase 13 (Expansion) ─────────── depends on Phase 12
  ├── 13.0 Sentiment Alerts ──── depends on F&G data (Phase 9.1, done)
  ├── 13.1 CETES ──────────────── depends on fixed_income schema (Phase 9.5, done)
  └── 13.2 Performance + Adv ─── depends on Bullet audit (12.2d)
```

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

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Trade race conditions | `Position.with_lock` in avg_cost recalculation handler |
| TrendScore calculation drift | Compare against known RSI-14 values for AAPL/BTC in test fixtures |
| Prescriptive language in Weekly Insight | Financial Expert reviews all text templates — no imperative verbs |
| Polygon earnings rate limit | Schedule sync weekly (Sunday 9am), stagger requests with `wait:` |
| Banxico API instability | Circuit breaker (threshold: 3, timeout: 300s), fallback to last known yield |
| System test flakiness | Use `driven_by :rack_test` (no browser), assert on content not layout |
| Performance audit reveals deep issues | Time-box Phase 12.2d to 2 days; create backlog items for larger fixes |
| Alpha Vantage 25 calls/day limit | Budget tracker via SystemLog, prioritized queue (portfolio > watchlist > rest) |

---

## Critical Reference Files

| File | Relevance |
|------|-----------|
| `app/models/trade.rb` | Core model for Trade Entry (11.1) — already has schema |
| `app/domain/alert_evaluator.rb` | Must extend for sentiment (13.0) and volume alerts (13.2) |
| `app/helpers/sparkline_helper.rb` | Pattern for F&G chart normalization (11.2a) |
| `app/domain/fundamental_calculator.rb` | Architecture pattern for TrendScoreCalculator (11.0) and YieldCalculator (13.1) |
| `app/event_handlers/recalculate_avg_cost_on_trade.rb` | Must add `with_lock` before Trade Entry (11.1e) |

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
