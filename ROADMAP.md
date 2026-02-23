# Stockerly — Roadmap de Implementacion (Phase 9+)

> Roadmap unificado que combina PLAN_SENTIMENT.md (Fear & Greed + DataSource Registry)
> y PLAN_IMPROVEMENTS.md (Historico 7D, News Feed, Indices, CETES).
>
> **Fecha:** 2026-02-23
> **Estado actual:** 990 specs, 95.85% line coverage, ALL Phase 9 complete
> **Fuente primaria:** PLAN_SENTIMENT.md (architecture-first)
> **Fuente complementaria:** PLAN_IMPROVEMENTS.md (feature additions)

---

## Estado de Fases (Completadas)

| Fase    | Nombre                                  | Specs   |
| ------- | --------------------------------------- | ------- |
| 0-4     | Setup, Public, Auth, App, Admin         | 85      |
| 4.5-4.6 | Auditorias + Componentes                | 200     |
| 5       | Modelos, Migraciones, Seeds             | 301     |
| 6-6.5   | Backend + Auditoria                     | 540     |
| 7       | Integraciones Externas                  | 654     |
| 8       | Polish & Completeness                   | 702     |
| **9.0** | **DataSource Registry & SyncLogging**   | **887** |
| **9.1** | **Fear & Greed Index**                  | **928** |
| **9.2** | **Historical Prices & Real Sparklines** | **947** |
| **9.3** | **News Feed with Polygon**              | **972** |
| **9.4** | **Market Indices Sync + IPC + VIX**     | **988** |
| **9.5** | **CETES Placeholder**                   | **990** |

---

## Fases — Resumen

| Fase     | Nombre                              | Tipo           | Est. Specs | Acumulado |
| -------- | ----------------------------------- | -------------- | ---------- | --------- |
| **9.0**  | DataSource Registry & SyncLogging   | **Completada** | +14        | 887       |
| **9.1**  | Fear & Greed Index                  | **Completada** | +41        | 928       |
| **9.2**  | Historical Prices & Real Sparklines | **Completada** | +19        | 947       |
| **9.3**  | News Feed with Polygon              | **Completada** | +25        | 972       |
| **9.4**  | Market Indices Sync + IPC + VIX     | **Completada** | +16        | 988       |
| **9.5**  | CETES Placeholder                   | **Completada** | +2         | 990       |
|          | *Phase 9 Total*                     |                | *~117*     |           |
| **10.0** | Foundation: Models + OVERVIEW Sync  | Pendiente      | ~30        | ~1020     |
| **10.1** | Financial Statements + Calculator   | Pendiente      | ~25        | ~1045     |
| **10.2** | UI: Asset Detail Page               | Pendiente      | ~20        | ~1065     |
| **10.3** | Crypto Fundamentals                 | Pendiente      | ~10        | ~1075     |
|          | *Phase 10 Total*                    |                | *~85*      |           |
|          | **Grand Total new**                 |                | **~202**   |           |

---

## Expert Panel Analysis

### Overlaps & Dependencies Between Plans

The two plans share significant infrastructure:

| Area                    | PLAN_SENTIMENT                                   | PLAN_IMPROVEMENTS                                   | Resolution                                                          |
| ----------------------- | ------------------------------------------------ | --------------------------------------------------- | ------------------------------------------------------------------- |
| **SyncLogging**         | Proposes concern to DRY 9 log blocks             | Jobs in 7D/News/Indices need same logging           | Phase 9.0 builds it once, all phases use it                         |
| **DataSourceRegistry**  | Central registry for 6+ sources                  | News, Indices, Backfill need gateway resolution     | Phase 9.0 builds it once, future sources auto-register              |
| **Admin buttons**       | Dynamic panel replaces hardcoded buttons         | New sources (News, Indices) would need new buttons  | Registry-driven admin eliminates per-source button work             |
| **Circuit breakers**    | Per-source config in registry                    | Backfill, News, Indices all need breakers           | Registry stores breaker config, `SyncSingleAssetJob` pattern reused |
| **Integration model**   | `requires_api_key` boolean for keyless providers | News (Polygon, has key), Indices (Yahoo, no key)    | Phase 9.0 adds the field                                            |
| **PolygonGateway**      | Not modified                                     | Gets `fetch_historical` + `fetch_news` methods      | Phases 9.2 and 9.3 extend it                                        |
| **YahooFinanceGateway** | Not modified                                     | Gets `fetch_index_quotes` method                    | Phase 9.4 extends it                                                |
| **Recurring schedule**  | Adds `refresh_fear_greed`                        | Adds backfill (event-driven), news sync, index sync | Each phase adds its entry to `recurring.yml`                        |

### Expert Verdicts

**Domain Architect:**

> Phase 9.0 as pure refactor is the correct call. The DataSourceRegistry follows the same pattern as EventBus — in-memory, boot-time, zero-dependency. SyncLogging as a concern is Rails-native and eliminates 40+ lines of duplication across 5 jobs. Crucially, this must land BEFORE any new data source to avoid compounding the duplication.

**Data Engineer:**

> The dependency graph is clear: Registry → Fear & Greed → Historical → News → Indices. Each phase extends existing gateways rather than creating parallel infrastructure. The `BackfillPriceHistoryJob` (Phase 9.2) should be event-driven (triggered by `AssetCreated`), not scheduled — this avoids unnecessary API calls.

**QA Engineer:**

> Phase 9.0 being a pure refactor means existing 702 specs are the safety net — if any break, the refactor introduced a bug. Each subsequent phase adds its own specs in isolation. Shared examples for job behavior (`include_examples "sync logging"`) should be created in Phase 9.0 to eliminate test duplication too.

**Product Strategist:**

> Fear & Greed before 7D sparklines makes sense: F&G is a new visible feature on the dashboard (replaces the static sentiment card), while sparklines are an improvement to existing data. Both are high-impact, but F&G is net-new functionality.

**Hotwire Engineer:**

> The sparkline component already accepts `heights` as a parameter. Phase 9.2 only needs a helper to normalize `close` prices to relative heights (0-100%). No Stimulus changes needed. The Fear & Greed card (Phase 9.1) needs a new partial with color-coded progress bar.

**Security Engineer:**

> CNN's undocumented API (Phase 9.1) requires a `User-Agent` header. This is fine for server-side fetching but document it clearly. The TradingView widget (Phase 9.3) requires CSP update: `frame-src https://www.tradingview.com`. No other security concerns — all new data is public, no user PII involved.

---

## Phase 9.0 — DataSource Registry & SyncLogging Foundation

> **Goal:** Establish the scalable pattern for all current and future data sources. Pure refactor — no new features, no new models.
> **Safety net:** All 702 existing specs must pass after every commit.

### Why First

The current codebase has:

- **9 duplicated `SystemLog.create!` blocks** across 5 job files
- **`case/when` gateway resolution** in both `SyncSingleAssetJob#gateway_for` and `SyncIntegrationJob#gateway_for`
- **Circuit breakers fragmented** in `SyncSingleAssetJob::CIRCUIT_BREAKERS` hash, accessed externally by `SyncBulkCryptoJob` and `SyncBulkBmvJob`
- **Admin buttons hardcoded** — each new source would need a new route, controller action, and button

All 4 problems get worse with every new data source. Fixing them now (before Fear & Greed, News, Indices, etc.) prevents the duplication from compounding.

### Steps

#### 9.0a — Integration Model Enhancement

**Migration:** `add_requires_api_key_to_integrations`

```ruby
add_column :integrations, :requires_api_key, :boolean, default: true, null: false
```

**Modify:** `app/models/integration.rb`

- Add conditional validation: `validates :api_key_encrypted, presence: true, if: :requires_api_key?`

**Modify:** `db/seeds.rb`

- Update Yahoo Finance integration: `requires_api_key: false`
- Add 2 new integrations: "Alternative.me" (Sentiment, no key), "CNN" (Sentiment, no key)

**Specs:** +2 (model validation for requires_api_key)

**Commit:** `Add requires_api_key to Integration model`

#### 9.0b — DataSource Registry

**New file:** `app/domain/data_source_registry.rb`

- `Data.define` struct for source metadata (key, name, icon, color, gateway_class, job_class, job_args, test_symbol, integration_name, circuit_breaker_config)
- Class methods: `.register`, `.find`, `.all`, `.for_integration`, `.clear!`
- Follows same pattern as `EventBus` (module with class methods, `@sources` hash)

**New file:** `config/initializers/data_sources.rb`

- Registers existing 4 providers: `:polygon_stocks`, `:coingecko_crypto`, `:yahoo_bmv`, `:fx_rates`
- 2 new F&G sources added later in Phase 9.1

**Specs:** +6 (register, find, all, for_integration, clear!, unknown key raises)

**Commit:** `Add DataSourceRegistry with source metadata`

#### 9.0c — SyncLogging Concern

**New file:** `app/jobs/concerns/sync_logging.rb`

- Methods: `log_sync_success(task_name, message:)`, `log_sync_failure(task_name, message)`, `log_sync_warning(task_name, message)`
- All create `SystemLog` entries with standardized format

**Specs:** +2 (shared example group for sync logging behavior)

**Commit:** `Add SyncLogging concern for standardized job logging`

#### 9.0d — Refactor Existing Jobs (Pure Refactor)

**Modify 5 files:**

- `app/jobs/sync_single_asset_job.rb` — `include SyncLogging`, remove `log_success`, `log_failure`
- `app/jobs/sync_bulk_crypto_job.rb` — `include SyncLogging`, remove `log_batch_success`, `log_batch_failure`
- `app/jobs/sync_bulk_bmv_job.rb` — `include SyncLogging`, remove `log_batch_success`, `log_batch_failure`
- `app/jobs/refresh_fx_rates_job.rb` — `include SyncLogging`, remove `log_success`, `log_failure`
- `app/jobs/sync_integration_job.rb` — Use `DataSourceRegistry.for_integration` instead of `case/when` for gateway resolution

**All 702 existing specs must still pass.**

**Commit:** `Refactor sync jobs to use SyncLogging and DataSourceRegistry`

#### 9.0e — Admin: Dynamic Data Sources Panel

**Modify:** `config/routes.rb`

- Add: `post "trigger_data_source/:key", to: "dashboard#trigger_data_source", as: :trigger_data_source` inside admin namespace

**Modify:** `app/controllers/admin/dashboard_controller.rb`

- Add `@data_sources = DataSourceRegistry.all` to `show`
- Add `trigger_data_source` action with rate limiting (5/min)

**Modify:** `app/views/admin/dashboard/show.html.erb`

- Replace hardcoded Quick Action buttons with registry-driven loop
- Add "Data Sources Health" section showing per-source status (integration status + last sync + error count 24h)

**Specs:** +0 (existing admin specs cover the view renders; may need minor adjustments)

**Commit:** `Replace hardcoded admin buttons with registry-driven data sources panel`

### Verification

```bash
bundle exec rspec         # ~712 specs, 0 failures
bin/rubocop               # 0 offenses
bin/rails db:seed         # Seeds run with new integrations
```

### Files Summary

| New Files (5)                                            | Modified Files (9)                              |
| -------------------------------------------------------- | ----------------------------------------------- |
| `db/migrate/..._add_requires_api_key_to_integrations.rb` | `app/models/integration.rb`                     |
| `app/domain/data_source_registry.rb`                     | `app/jobs/sync_single_asset_job.rb`             |
| `app/jobs/concerns/sync_logging.rb`                      | `app/jobs/sync_bulk_crypto_job.rb`              |
| `config/initializers/data_sources.rb`                    | `app/jobs/sync_bulk_bmv_job.rb`                 |
| `spec/domain/data_source_registry_spec.rb`               | `app/jobs/refresh_fx_rates_job.rb`              |
|                                                          | `app/jobs/sync_integration_job.rb`              |
|                                                          | `app/controllers/admin/dashboard_controller.rb` |
|                                                          | `app/views/admin/dashboard/show.html.erb`       |
|                                                          | `db/seeds.rb`                                   |

---

## Phase 9.1 — Fear & Greed Index

> **Goal:** Replace the static Market Sentiment card on the dashboard with real Fear & Greed data from Alternative.me (crypto) and CNN (stocks).
> **Depends on:** Phase 9.0 (Registry, SyncLogging, Integration model)

### Data Sources

| Market | Provider           | Endpoint                                                                    | Auth              | Frequency |
| ------ | ------------------ | --------------------------------------------------------------------------- | ----------------- | --------- |
| Crypto | Alternative.me     | `GET https://api.alternative.me/fng/?limit=1`                               | None              | Daily     |
| Stocks | CNN (undocumented) | `GET https://production.dataviz.cnn.io/index/fearandgreed/graphdata/{date}` | User-Agent header | Daily     |

### Steps

#### 9.1a — FearGreedReading Model & Migration

**Migration:** `create_fear_greed_readings`

```ruby
create_table :fear_greed_readings do |t|
  t.string   :index_type,     null: false   # "crypto" | "stocks"
  t.integer  :value,          null: false   # 0-100
  t.string   :classification, null: false   # "Extreme Fear" .. "Extreme Greed"
  t.string   :source,         null: false   # "alternative.me" | "cnn"
  t.jsonb    :component_data, default: {}   # CNN sub-indicators
  t.datetime :fetched_at,     null: false
  t.timestamps
end
add_index :fear_greed_readings, [:index_type, :fetched_at]
```

**New file:** `app/models/fear_greed_reading.rb`

- Validations: index_type in `%w[crypto stocks]`, value 0..100, presence on all
- Scopes: `.crypto`, `.stocks`, `.recent`, `.latest_crypto`, `.latest_stocks`
- Instance: `stale?` → `fetched_at < 25.hours.ago`
- Class: `classify(value)` → 5 labels (Extreme Fear, Fear, Neutral, Greed, Extreme Greed)

**New file:** `spec/factories/fear_greed_readings.rb` (traits: `:crypto`, `:stocks`)
**New file:** `spec/models/fear_greed_reading_spec.rb`

**Specs:** +8

**Commit:** `Add FearGreedReading model and migration`

#### 9.1b — Fear & Greed Gateways

**New file:** `app/gateways/crypto_fear_greed_gateway.rb`

- Faraday → `https://api.alternative.me`, 5s timeout, retry middleware
- `fetch_index` → `Success({ value:, classification:, fetched_at:, component_data: })`
- Handles: 429, 5xx, timeout

**New file:** `app/gateways/stock_fear_greed_gateway.rb`

- Faraday → `https://production.dataviz.cnn.io`, 10s timeout
- Headers: `User-Agent: "Mozilla/5.0 (compatible; Stockerly/1.0)"`
- `fetch_index` → same Success shape + `component_data` with 7 CNN sub-indicators

**Specs:** +11 (WebMock stubs for success, 429, 500, timeout, malformed JSON)

**Commit:** `Add crypto and stock Fear & Greed gateways`

#### 9.1c — Job, Event & Handler

**New file:** `app/events/fear_greed_updated.rb`
**New file:** `app/event_handlers/log_fear_greed_update.rb`
**New file:** `app/jobs/refresh_fear_greed_job.rb`

- `include SyncLogging`
- Calls both gateways independently (one failure doesn't block the other)
- Each wrapped in its own `CircuitBreaker` (threshold: 3, timeout: 300s)
- On success: creates `FearGreedReading`, `log_sync_success`, publishes `FearGreedUpdated`

**Modify:** `config/initializers/event_subscriptions.rb` — subscribe `FearGreedUpdated` → `LogFearGreedUpdate`
**Modify:** `config/initializers/data_sources.rb` — register `:crypto_fear_greed` and `:stock_fear_greed`
**Modify:** `config/recurring.yml` — add `refresh_fear_greed` at 6am daily

**Specs:** +10 (event, handler, job)

**Commit:** `Add RefreshFearGreedJob with events and handler`

#### 9.1d — Dashboard Integration

**Modify:** `app/domain/market_sentiment.rb`

- Add `MarketSentiment.fear_greed` → `{ crypto: { value:, label:, stale:, fetched_at:, component_data: }, stocks: { ... } }`
- Falls back to `{ value: 50, label: "Neutral", stale: true }` when no data

**Modify:** `app/use_cases/dashboard/assemble.rb`

- Add `fear_greed: MarketSentiment.fear_greed` to Success result

**Modify:** `app/controllers/dashboard_controller.rb`

- Add `@fear_greed = data[:fear_greed]`

**New file:** `app/views/components/_fear_greed_card.html.erb`

- Accepts: `title`, `data`, `icon`
- Color coding: red (0-24), orange (25-44), amber (45-55), lime (56-74), green (75-100)
- Progress bar, value + classification label, "Updated X ago" or "Data may be outdated"

**Modify:** `app/views/dashboard/show.html.erb`

- Replace the single Market Sentiment card with 2 Fear & Greed cards (crypto + stocks)

**Modify:** `db/seeds.rb` — add 2 seed FearGreedReading records

**Specs:** +6 (market_sentiment +4, dashboard/assemble +2)

**Commit:** `Display Fear & Greed indices on dashboard`

### UI Design Needed

The Fear & Greed card (`_fear_greed_card.html.erb`) needs a Stitch design:

**Stitch prompt:**

> Design a compact Fear & Greed index card for a financial dashboard. The card should show: (1) a title like "Crypto Fear & Greed" with a Material Symbol icon, (2) a large number (0-100) with the classification label below (e.g. "25 — Extreme Fear"), (3) a horizontal color-coded progress bar (red → orange → amber → lime → green), (4) a subtle "Updated 6h ago" timestamp. Use Tailwind CSS, dark mode support, bg-white/dark:bg-slate-900, rounded-xl border. Make it fit in a 4-column grid next to similar stat cards. Color scheme: red for 0-24, orange for 25-44, amber for 45-55, lime for 56-74, green for 75-100. Font: Inter. Icons: Material Symbols Rounded.

### Verification

```bash
bundle exec rspec         # ~747 specs, 0 failures
bin/dev                   # Visit /dashboard → see 2 Fear & Greed cards with seed data
```

---

## Phase 9.2 — Historical Prices & Real Sparklines

> **Goal:** Replace hardcoded sparkline bars with real 7-day price data. Add historical price backfill for new assets.
> **Depends on:** Phase 9.0 (SyncLogging). Does NOT depend on 9.1.

### Current State

- `AssetPriceHistory` model exists with OHLCV columns and `.recent(7)` scope
- `RecordPriceHistory` event handler accumulates daily data from `AssetPriceUpdated` events
- `_sparkline.html.erb` component exists but uses hardcoded heights based on `:up`/`:down`
- Trends page already uses real `AssetPriceHistory` data with SVG chart (30 days)
- PolygonGateway only fetches previous-day close, not historical range

### Steps

#### 9.2a — Gateway Historical Methods

**Modify:** `app/gateways/polygon_gateway.rb`

- Add `fetch_historical(symbol, from_date, to_date)` using `/v2/aggs/ticker/{symbol}/range/1/day/{from}/{to}`
- Returns `Success([{ date:, open:, high:, low:, close:, volume: }, ...])`

**Modify:** `app/gateways/coingecko_gateway.rb`

- Add `fetch_historical(symbol, days)` using `/coins/{id}/market_chart?vs_currency=usd&days={days}`
- Returns same Success shape

**Specs:** +6 (WebMock stubs for both gateways, success + error cases)

**Commit:** `Add historical price fetch to Polygon and CoinGecko gateways`

#### 9.2b — BackfillPriceHistoryJob

**New file:** `app/jobs/backfill_price_history_job.rb`

- `include SyncLogging`
- Receives `asset_id`, fetches 30 days of history via appropriate gateway
- Upserts into `AssetPriceHistory` by `[asset_id, date]`
- Registered in DataSourceRegistry as part of the asset creation flow

**New file:** `app/event_handlers/backfill_history_on_asset_creation.rb`

- Listens to `AssetCreated` event
- Enqueues `BackfillPriceHistoryJob.perform_later(event.asset_id)`
- `self.async? = true`

**Modify:** `config/initializers/event_subscriptions.rb`

- Subscribe `AssetCreated` → `BackfillHistoryOnAssetCreation`

**Specs:** +5 (job spec + handler spec)

**Commit:** `Add BackfillPriceHistoryJob triggered on asset creation`

#### 9.2c — Sparkline Helper & Real Data Connection

**New file:** `app/helpers/sparkline_helper.rb`

- `price_sparkline_data(asset, days: 7)` → `{ heights: [30, 45, ...], direction: :up }`
- Queries `asset.asset_price_histories.recent(days).pluck(:close)`
- Normalizes to 0-100 relative heights
- Falls back to hardcoded data if no history available

**Modify:** `app/views/components/_sparkline.html.erb`

- Accept optional `heights` parameter; use it when provided, otherwise fall back to direction-based

**Modify views (3 files):**

- `app/views/market/_listings_table.html.erb` — pass real sparkline data
- `app/views/dashboard/_watchlist_table.html.erb` — pass real sparkline data
- `app/views/profiles/show.html.erb` — pass real sparkline data (watchlist section)

**Specs:** +7 (helper spec for normalization, edge cases, fallback)

**Commit:** `Connect sparklines to real price history data`

### Verification

```bash
bundle exec rspec         # ~765 specs, 0 failures
bin/dev                   # Visit /market → sparklines show real history patterns
```

---

## Phase 9.3 — News Feed with Polygon

> **Goal:** Replace seed-only news articles with live data from Polygon.io's news API. Add infinite scroll and TradingView widget.
> **Depends on:** Phase 9.0 (Registry, SyncLogging)

### Current State

- `NewsArticle` model exists (title, summary, source, url, image_url, published_at, related_ticker)
- `NewsController#index` exists with `News::ListArticles` use case + Pagy pagination
- `/news` view exists (featured hero, 2-column grid, sidebar) — data from 3 seed articles
- No gateway fetches news, no sync job

### Steps

#### 9.3a — Polygon News Gateway Method

**Modify:** `app/gateways/polygon_gateway.rb`

- Add `fetch_news(ticker: nil, limit: 20, published_after: nil)`
- Endpoint: `GET /v2/reference/news`
- Maps response to `[{ title:, summary:, source:, url:, image_url:, published_at:, related_ticker: }]`

**Specs:** +4 (success, rate limit, error, empty)

**Commit:** `Add fetch_news method to PolygonGateway`

#### 9.3b — News Sync Use Case & Job

**New file:** `app/use_cases/news/sync_articles.rb`

- Calls `PolygonGateway#fetch_news`
- Upserts by URL (avoids duplicates)
- Publishes `NewsSynced` event with count

**New file:** `app/events/news_synced.rb`
**New file:** `app/event_handlers/log_news_sync.rb`
**New file:** `app/jobs/sync_news_job.rb`

- `include SyncLogging`
- Calls `News::SyncArticles.call`

**Modify:** `config/initializers/data_sources.rb` — register `:polygon_news`
**Modify:** `config/initializers/event_subscriptions.rb` — subscribe `NewsSynced` → `LogNewsSync`
**Modify:** `config/recurring.yml` — add `sync_news` every 30 minutes

**Specs:** +8 (use case, event, handler, job)

**Commit:** `Add SyncNewsJob with Polygon news integration`

#### 9.3c — News View Enhancements

**New file:** `app/javascript/controllers/infinite_scroll_controller.js`

- Stimulus controller with `IntersectionObserver`
- Fetches next page via Turbo Frame

**Modify:** `app/views/news/index.html.erb`

- Add Turbo Frame for paginated content
- Add TradingView Top Stories widget in sidebar (iframe)
- Add filter chips for source, time range

**Modify:** `config/initializers/content_security_policy.rb`

- Allow `frame-src https://www.tradingview.com` (if CSP is configured)

**Optional migration:** Add `tickers` (jsonb array) to `news_articles` for multi-ticker support. Keep `related_ticker` for backwards compatibility.

**Specs:** +8 (request specs for filters, pagination; use case specs)

**Commit:** `Enhance news page with infinite scroll, filters, and TradingView widget`

### UI Design Needed

**Stitch prompt for news feed enhancements:**

> Redesign the news feed page for a financial platform. The page has: (1) A filter bar at the top with pill-shaped chips for sources (Bloomberg, Reuters, WSJ, All), a time range dropdown (Today, This Week, This Month), and a search field. (2) A featured article hero card taking full width with large image, title, source badge, and time ago. (3) A 2-column grid of article cards below with thumbnail on the left (80x80), title, source tag, ticker tag (like "AAPL" in a blue pill), and "2h ago" timestamp. (4) A right sidebar with a TradingView widget placeholder (300px height, labeled "Market Headlines") and a "From Your Watchlist" section. (5) An infinite scroll trigger at the bottom (a subtle "Loading more..." with spinner). Use Tailwind CSS 4, dark mode, Inter font, Material Symbols. Primary color #004a99.

### Verification

```bash
bundle exec rspec         # ~785 specs, 0 failures
bin/dev                   # Visit /news → see live articles from Polygon
```

---

## Phase 9.4 — Market Indices Sync + IPC + VIX

> **Goal:** Make MarketIndex values live (no longer static seeds). Add IPC (Mexico), sync via Yahoo Finance, show VIX as volatility indicator.
> **Depends on:** Phase 9.0 (Registry, SyncLogging)

### Current State

- `MarketIndex` model exists with 4 seeded indices (SPX, NDX, DJI, UKX) — static, never updated
- `VIX` exists as an `Asset` (type: index) but not as a `MarketIndex`
- `YahooFinanceGateway` exists but only has `fetch_price` and `fetch_bulk_prices` (for BMV stocks)
- Dashboard and Market page display indices from `MarketIndex.major` — always shows seed values

### Decision: Keep MarketIndex Model

MarketIndex is kept as a separate model from Asset. Indices like S&P 500 are not tradeable assets in Stockerly — they're reference data displayed on the dashboard and market page. This avoids mixing concerns.

### Steps

#### 9.4a — YahooFinanceGateway: Index Quotes

**Modify:** `app/gateways/yahoo_finance_gateway.rb`

- Add `fetch_index_quotes(symbols)` method
- Symbols: `['^GSPC', '^IXIC', '^DJI', '^FTSE', '^MXX', '^VIX']`
- Returns `Success([{ symbol:, name:, value:, change_percent:, is_open: }])`
- Maps Yahoo symbols to our symbols (^GSPC → SPX, ^IXIC → NDX, etc.)

**Specs:** +4

**Commit:** `Add fetch_index_quotes to YahooFinanceGateway`

#### 9.4b — SyncMarketIndicesJob

**New file:** `app/jobs/sync_market_indices_job.rb`

- `include SyncLogging`
- Calls `YahooFinanceGateway#fetch_index_quotes`
- Upserts `MarketIndex` records by symbol
- Publishes `MarketIndicesUpdated` event

**New file:** `app/events/market_indices_updated.rb`
**New file:** `app/event_handlers/log_market_indices_update.rb`

**Modify:** `config/initializers/data_sources.rb` — register `:yahoo_indices`
**Modify:** `config/initializers/event_subscriptions.rb`
**Modify:** `config/recurring.yml` — add `sync_market_indices` every 10 minutes

**Specs:** +6

**Commit:** `Add SyncMarketIndicesJob with Yahoo Finance`

#### 9.4c — IPC + VIX + Updated Views

**Modify:** `db/seeds.rb`

- Add IPC (^MXX) to MarketIndex seeds
- Add VIX to MarketIndex seeds (separate from VIX Asset)

**Modify:** `app/models/market_index.rb`

- Update scope `.major` to include IPC: `%w[SPX NDX DJI UKX IPC]`
- Add scope `.vix` → `find_by(symbol: 'VIX')`

**Modify:** `app/views/market/index.html.erb`

- Show 5 index cards + VIX indicator badge
- Show market status (Open/Closed) from `MarketHours`

**Modify:** `app/views/dashboard/_market_status.html.erb` (or equivalent)

- Use live index values instead of seed values

**Specs:** +5

**Commit:** `Add IPC index, VIX indicator, and live index display`

### UI Design Needed

**Stitch prompt for market indices cards:**

> Design a horizontal row of 5 market index cards for a financial dashboard. Each card shows: index name (e.g. "S&P 500"), current value in large text (e.g. "5,214.33"), change percent with color (green +0.42%, red -0.12%), and a small status indicator (green dot = Open, gray dot = Closed). Below the 5 cards, add a VIX indicator bar: "VIX 14.33" with a horizontal scale from "Low Volatility" to "High Volatility", color-coded (green < 20, amber 20-30, red > 30). The 5 indices are: S&P 500, NASDAQ, DOW JONES, FTSE 100, IPC Mexico. Use Tailwind CSS 4, dark mode, rounded-xl cards with border, Inter font, Material Symbols.

### Verification

```bash
bundle exec rspec         # ~800 specs, 0 failures
bin/dev                   # Visit /market → indices show live values
```

---

## Phase 9.5 — CETES Placeholder

> **Goal:** Add `fixed_income` asset type and schema fields for future CETES/bond support. Minimal implementation — placeholder only.
> **Depends on:** Nothing (independent)

### Steps

#### 9.5a — Migration & Model Update

**Migration:** `add_fixed_income_support_to_assets`

```ruby
# Add fixed_income to enum (value: 4)
# Note: enum change requires updating the Ruby enum definition, not a DB migration
# for PostgreSQL integer enums

add_column :assets, :yield_rate,     :decimal, precision: 8, scale: 4
add_column :assets, :maturity_date,  :date
add_column :assets, :face_value,     :decimal, precision: 15, scale: 2
```

**Modify:** `app/models/asset.rb`

- Add `fixed_income: 4` to `asset_type` enum
- Add scope `.fixed_income` → `where(asset_type: :fixed_income)`

**Modify:** `db/seeds.rb`

- Add 2 CETES examples (28-day and 364-day)

**Specs:** +3 (enum value, scope, validation)

**Commit:** `Add fixed_income asset type with yield and maturity fields`

#### 9.5b — UI Badge & Filter

**Modify:** Market page filter to include "Fixed Income" option
**Modify:** `_asset_type_badge` component (if exists) to handle `:fixed_income` with appropriate color

**Specs:** +2

**Commit:** `Add fixed income badge and filter in market UI`

### Verification

```bash
bundle exec rspec         # ~805 specs, 0 failures
bin/rails db:seed         # CETES examples appear in assets
```

---

## UI/UX Design Requirements Summary

These are the new visual components that need Stitch designs before or during implementation:

| Phase | Component                                     | Priority | Stitch Prompt |
| ----- | --------------------------------------------- | -------- | ------------- |
| 9.0e  | Admin Data Sources Health Panel               | Medium   | See below     |
| 9.1d  | Fear & Greed Card (x2)                        | High     | See Phase 9.1 |
| 9.3c  | News Feed Enhanced (filters, infinite scroll) | High     | See Phase 9.3 |
| 9.4c  | Market Index Cards Row + VIX Bar              | Medium   | See Phase 9.4 |

### Stitch Prompt: Admin Data Sources Health Panel

> Design an admin dashboard section titled "Data Sources" for a financial platform admin panel. Show a grid of 6 data source cards in 2 rows of 3. Each card has: (1) a Material Symbol icon with color accent (indigo for stocks, emerald for crypto, amber for FX, purple for sentiment), (2) source name (e.g. "US Stocks — Polygon.io"), (3) status badge (Connected/green, Syncing/amber, Disconnected/red), (4) "Last sync: 2 min ago" text, (5) "Errors 24h: 0" counter, (6) a "Sync Now" button. The cards should be compact (not full-width). Below the grid, add a note: "Sources are auto-discovered from the DataSourceRegistry." Use Tailwind CSS 4, dark mode, Inter font, Material Symbols. Style: admin/professional, minimal.

---

## Dependency Graph

```
Phase 9.0 (Foundation)
  ├── Phase 9.1 (Fear & Greed) ─── uses Registry, SyncLogging, Integration model
  ├── Phase 9.2 (Historical 7D) ── uses SyncLogging
  ├── Phase 9.3 (News Feed) ────── uses Registry, SyncLogging
  └── Phase 9.4 (Indices) ──────── uses Registry, SyncLogging

Phase 9.5 (CETES) ─────────────── independent (schema only)
```

Phases 9.1-9.4 all depend on 9.0 but are independent of each other. The chosen order (F&G → 7D → News → Indices) is by value/effort ratio, not by dependency.

---

## Risk Mitigation

| Risk                              | Mitigation                                                                                       |
| --------------------------------- | ------------------------------------------------------------------------------------------------ |
| CNN API breaks/changes            | Circuit breaker (3 failures → open 5 min). Dashboard shows "Neutral 50" + "Data may be outdated" |
| Alternative.me down               | Independent fetch per source. Crypto F&G failure doesn't block stocks F&G                        |
| Polygon news rate limit           | 1 fetch/30 min well within Basic tier (5 req/min). Upsert avoids duplicates                      |
| Yahoo Finance blocks requests     | User-Agent header, reasonable rate (1 req/10 min for indices). Fallback to seed values           |
| Registry drift vs recurring.yml   | Smoke test verifies every `recurring.yml` entry has a registry entry                             |
| Refactor breaks existing jobs     | Phase 9.0 is pure refactor — 702 specs are the safety net                                        |
| Data growth                       | F&G: ~730 rows/year. News: ~14K/year (20 articles × 48 fetches/day). Indexed.                    |
| Alpha Vantage 25 calls/day limit  | OVERVIEW-first (1 call = 50+ metrics). Budget tracker via SystemLog. Prioritized queue            |
| Alpha Vantage rate limit quirk    | Inspect body for "Note"/"Information" keys — returns HTTP 200 (not 429)                          |
| Financial statement JSONB bloat   | ~50KB/statement × 20 statements/asset × 200 assets = ~200MB. Well within PostgreSQL limits       |
| Incorrect metric calculations     | Extensive unit tests for FundamentalCalculator. D/E uses total_debt (not total_liabilities)       |
| Regulatory risk (investment advice)| Contextual guidance only, GAAP-only, disclaimer on all pages, no prescriptive language           |
| API provider lock-in              | FundamentalsGateway base class enables provider swap (FMP, Polygon) without touching domain       |

---

## Phase 10 — Financial Fundamentals & Asset Detail

> **Source:** `PLAN_METRICS.md` (reviewed by Domain Architect, Financial Expert, Data Engineer)
> **Goal:** Add fundamental financial metrics (valuation, profitability, debt, growth, dividends) to Stockerly.
> Replace price-only views with comprehensive asset analysis. Educational UX with help tooltips.
> **Data source:** Alpha Vantage (free tier, 25 calls/day). OVERVIEW-first strategy.
> **Designs:** `designs/detalle_de_asset_-_aapl/`, `designs/aapl_statements_tab_-_stockerly/`,
> `designs/stockerly_-_adaptive_metrics/`, `designs/stockerly_-_tooltip_component_detail/`

### Phase 10 Summary

| Fase      | Nombre                                         | Tipo         | Est. Specs | Acumulado |
| --------- | ---------------------------------------------- | ------------ | ---------- | --------- |
| **10.0**  | Foundation: Models + OVERVIEW Sync             | Backend      | ~30        | ~1020     |
| **10.1**  | Financial Statements + Calculator              | Backend      | ~25        | ~1045     |
| **10.2**  | UI: Asset Detail Page                          | Frontend     | ~20        | ~1065     |
| **10.3**  | Crypto Fundamentals                            | Cross-stack  | ~10        | ~1075     |
|           | **Total Phase 10**                             |              | **~85**    |           |

### Key Architecture Decisions (Expert-Reviewed)

| Decision | Resolution | Expert |
|----------|-----------|--------|
| MetricDefinition storage | **Ruby module (Data.define)**, not DB table | Domain Architect |
| Event chain | **Two events:** `FinancialStatementsSynced` → `AssetFundamentalsUpdated` | Domain Architect |
| Price-dependent metrics | **FundamentalPresenter** computes live at render (not stored) | Domain Architect |
| Debt-to-Equity formula | **total_debt / equity** (NOT total_liabilities) | Financial Expert |
| Guidance language | **Contextual**, no prescriptive "buy/sell" advice | Financial Expert |
| TTM calculation | **Sum of last 4 quarters**, not latest annual | Financial Expert |
| GAAP vs Non-GAAP | **GAAP only**, noted visibly in UI | Financial Expert |
| Job granularity | **1 job = 1 API call** (atomic, resilient) | Data Engineer |
| API priority | **OVERVIEW first** (50+ metrics/1 call), Statements later | Data Engineer |
| Rate limit detection | **Inspect body for "Note" key** (Alpha Vantage returns HTTP 200) | Data Engineer |

---

### Phase 10.0 — Foundation: Models + MetricDefinitions + OVERVIEW Sync

> **Goal:** Immediate value — 50+ metrics per asset from a single API call/day.
> **Depends on:** Phase 9.0 (DataSourceRegistry, SyncLogging, Integration model)

#### 10.0a — Database Models (2 migrations + 1 column)

**Migration 1:** `create_financial_statements`

```ruby
create_table :financial_statements do |t|
  t.references :asset, null: false, foreign_key: true
  t.string   :statement_type, null: false   # income_statement, balance_sheet, cash_flow
  t.string   :period_type, null: false      # annual, quarterly
  t.date     :fiscal_date_ending, null: false
  t.integer  :fiscal_year
  t.integer  :fiscal_quarter
  t.string   :currency, default: "USD"
  t.jsonb    :data, null: false, default: {}
  t.string   :source
  t.datetime :fetched_at
  t.timestamps
end
add_index :financial_statements, [:asset_id, :statement_type, :period_type, :fiscal_date_ending],
          unique: true, name: "idx_fin_stmts_unique"
```

**Migration 2:** `create_asset_fundamentals`

```ruby
create_table :asset_fundamentals do |t|
  t.references :asset, null: false, foreign_key: true
  t.string   :period_label, null: false   # "TTM", "OVERVIEW", "FY2025"
  t.jsonb    :metrics, null: false, default: {}
  t.string   :source                       # "calculated", "api_overview", "blended"
  t.datetime :calculated_at
  t.timestamps
end
add_index :asset_fundamentals, [:asset_id, :period_label], unique: true
```

**Migration 3:** `add_fundamentals_synced_at_to_assets`

```ruby
add_column :assets, :fundamentals_synced_at, :datetime
```

**Models:** `FinancialStatement` (enums, scopes, JSONB key validation), `AssetFundamental` (scopes)
**Factories + Specs:** +10

**Commit:** `Add FinancialStatement and AssetFundamental models`

#### 10.0b — MetricDefinitions Module

**New file:** `app/domain/metric_definitions.rb`

- `Data.define` struct: key, category, display_name, short_desc, context_guidance, format_type, display_order, icon
- 30+ definitions across 7 categories (valuation, profitability, health, growth, dividends, risk, identity)
- Class methods: `.find(key)`, `.by_category(category)`, `.categories`
- Follows same pattern as `DataSourceRegistry`

**Specs:** +4 (all definitions present, valid categories, no duplicates, find/by_category)

**Commit:** `Add MetricDefinitions module with 30+ metric definitions`

#### 10.0c — Alpha Vantage Gateway

**New file:** `app/gateways/fundamentals_gateway.rb` (base class)
**New file:** `app/gateways/alpha_vantage_gateway.rb` (concrete implementation)

- `fetch_overview(symbol)` — OVERVIEW endpoint (Phase A only)
- **Critical:** Alpha Vantage returns HTTP 200 with `"Note"` key on rate limit (NOT 429)
- Error types: `:rate_limited`, `:auth_error`, `:gateway_error`, `:not_found`, `:timeout`, `:parse_error`
- Faraday with retry middleware, 10s timeout

**Specs:** +6 (WebMock: success, rate_limit "Note", auth "Information", timeout, 500, parse error)

**Commit:** `Add AlphaVantageGateway with OVERVIEW endpoint`

#### 10.0d — FundamentalPresenter + Jobs + Events

**New file:** `app/domain/fundamental_presenter.rb`

- Computes price-dependent metrics at render time: P/E, P/B, P/S, EV/EBITDA, FCF Yield
- Uses live `current_price` + stored `diluted_eps`, `total_revenue`, etc.

**New file:** `app/jobs/sync_fundamental_job.rb` (1 asset, 1 function)
**New file:** `app/jobs/sync_all_fundamentals_job.rb` (orchestrator with prioritization + budget)

- Priority: portfolio assets > watchlist assets > rest
- Budget tracking via SystemLog entries (25 calls/day)
- Staggered enqueueing: `wait: index * 15.seconds` (20% headroom vs 5 calls/min limit)

**New file:** `app/events/asset_fundamentals_updated.rb`
**New file:** `app/event_handlers/log_fundamentals_update.rb`

**Modify:** `config/initializers/data_sources.rb` — register `:alpha_vantage_fundamentals`
**Modify:** `config/initializers/event_subscriptions.rb`
**Modify:** `config/recurring.yml` — add `sync_fundamentals_overview` daily at 7am UTC
**Modify:** `db/seeds.rb` — add "Alpha Vantage" integration + sample AssetFundamental

**Specs:** +10 (presenter, jobs, event, handler)

**Commit:** `Add OVERVIEW sync pipeline with FundamentalPresenter`

#### Phase 10.0 Verification

```bash
bundle exec rspec         # ~1020 specs, 0 failures
bin/rubocop               # 0 offenses
bin/rails db:seed         # Alpha Vantage integration + sample fundamentals
```

---

### Phase 10.1 — Financial Statements + Calculator

> **Goal:** Self-calculated metrics from raw statements, multi-year analysis.
> **Depends on:** Phase 10.0

#### 10.1a — Extend AlphaVantageGateway (3 statement methods)

**Modify:** `app/gateways/alpha_vantage_gateway.rb`

- Add `fetch_income_statement(symbol)`, `fetch_balance_sheet(symbol)`, `fetch_cash_flow(symbol)`
- Each returns `Success(body)` with annual + quarterly reports

**Specs:** +4 (WebMock stubs per function)

**Commit:** `Add financial statement fetch methods to AlphaVantageGateway`

#### 10.1b — FundamentalCalculator Domain Service

**New file:** `app/domain/fundamental_calculator.rb`

- Pure stateless calculator, receives data → returns metrics hash
- **Debt-to-Equity:** `total_debt / equity` (short + long term, NOT total_liabilities)
- **TTM:** Sum of last 4 quarterly reports (balance sheet uses latest snapshot)
- **CAGR:** Guards against negative/zero values
- **Interest Coverage:** Returns `nil` when interest_expense = 0
- Covers: profitability, health, growth, dividend metrics

**Specs:** +10 (every formula, edge cases: nil, zero, negative, "None" strings)

**Commit:** `Add FundamentalCalculator with all metric formulas`

#### 10.1c — Use Case + Events + Handlers

**New file:** `app/use_cases/market/load_asset_detail.rb`
**New file:** `app/events/financial_statements_synced.rb`
**New file:** `app/event_handlers/recalculate_fundamentals_on_statements_sync.rb`
**New file:** `app/event_handlers/broadcast_fundamentals_update.rb`

**Reactive chain:**
```
SyncFundamentalJob → saves statements → publishes FinancialStatementsSynced
  → RecalculateFundamentalsOnStatementsSynced → FundamentalCalculator → upserts AssetFundamental
    → publishes AssetFundamentalsUpdated → BroadcastFundamentalsUpdate (Turbo Stream)
```

**Modify:** `config/initializers/event_subscriptions.rb` — wire both handlers
**Modify:** `config/recurring.yml` — add `sync_fundamentals_statements` weekly at 8am UTC (Sunday)
**Modify:** `app/jobs/sync_fundamental_job.rb` — extend `persist` for statement types

**Specs:** +11 (use case, events, handlers)

**Commit:** `Add statement sync pipeline with FundamentalCalculator`

#### Phase 10.1 Verification

```bash
bundle exec rspec         # ~1045 specs, 0 failures
bin/rubocop               # 0 offenses
```

---

### Phase 10.2 — UI: Asset Detail Page

> **Goal:** User-facing metric cards with help tooltips, tabbed layout, statement tables.
> **Depends on:** Phase 10.1
> **Designs:** `designs/detalle_de_asset_-_aapl/screen.png`, `designs/aapl_statements_tab_-_stockerly/screen.png`, `designs/stockerly_-_tooltip_component_detail/screen.png`

#### 10.2a — Route + Controller + Summary Tab

**Modify:** `config/routes.rb` — add `GET /market/:symbol` → `MarketController#show`

**Modify:** `app/controllers/market_controller.rb`

- Add `show` action: calls `Market::LoadAssetDetail`, passes fundamentals to `FundamentalPresenter`
- Loads `MetricDefinitions` for help icons

**New file:** `app/views/market/show.html.erb` — tabbed layout per design

**New files (partials):**
- `_metric_card.html.erb` — reusable card with value, label, help icon, context
- `_metric_grid.html.erb` — responsive grid of metric cards
- `_summary_tab.html.erb` — top 10 metrics (P/E, FCF, CAGR, D/E, ROE, etc.)
- `_disclaimer.html.erb` — regulatory disclaimer footer

**Specs:** +8 (request specs: show, not_found, missing fundamentals)

**Commit:** `Add asset detail page with summary tab and metric cards`

#### 10.2b — Category Tabs + Statements Tab

**New files (partials):**
- `_valuation_tab.html.erb`, `_profitability_tab.html.erb`, `_health_tab.html.erb`
- `_growth_tab.html.erb`, `_dividends_tab.html.erb`
- `_statements_tab.html.erb` — multi-year financial statement table per design
- Income Statement / Balance Sheet / Cash Flow sub-tabs, Annual/Quarterly toggle

**Modify:** Navigation links in market listing table + watchlist → link to `/market/:symbol`

**Specs:** +6 (request specs for each tab, statement rendering)

**Commit:** `Add category tabs, statements tab, and navigation links`

#### 10.2c — Tooltip Stimulus Controller + Help Icons

**New file:** `app/javascript/controllers/metric_tooltip_controller.js`

- Opens popover/tooltip on help icon click (per tooltip design)
- Renders: definition, context guidance, disclaimer note
- Data from `MetricDefinitions` passed via `data-*` attributes

**Specs:** +6 (system specs: tooltip display, content, dismiss)

**Commit:** `Add metric tooltip controller with help icon popovers`

#### Phase 10.2 Verification

```bash
bundle exec rspec         # ~1065 specs, 0 failures
bin/dev                   # Visit /market/AAPL → see full asset detail with tabs and tooltips
```

---

### Phase 10.3 — Crypto Fundamentals

> **Goal:** Crypto-specific metrics from CoinGecko (no additional API cost).
> **Depends on:** Phase 10.2
> **Design:** `designs/stockerly_-_adaptive_metrics/screen.png`

#### 10.3a — Enrich CoinGecko Gateway

**Modify:** `app/gateways/coingecko_gateway.rb`

- Replace `/simple/price` with `/coins/markets` for richer data
- Extract: circulating_supply, total_supply, fully_diluted_valuation, ath, atl, ath_change_percentage, 24h_volume

**Specs:** +3

**Commit:** `Enrich CoinGecko gateway with extended market data`

#### 10.3b — Crypto MetricDefinitions + Conditional Rendering

**Modify:** `app/domain/metric_definitions.rb` — add crypto-specific definitions (supply, FDV, ATH/ATL, volume ratio)

**Modify:** Asset detail view — conditional rendering by `asset.asset_type`:
- Stocks: valuation, profitability, health, growth, dividends tabs
- Crypto: market data, supply, on-chain tabs (per adaptive metrics design)

**Modify:** `_summary_tab.html.erb` — swap metrics based on asset type

**Specs:** +7 (crypto rendering, conditional logic, new definitions)

**Commit:** `Add crypto-specific metrics with adaptive rendering`

#### Phase 10.3 Verification

```bash
bundle exec rspec         # ~1075 specs, 0 failures
bin/dev                   # Visit /market/BTC → see crypto-specific metrics
```

---

### Phase 10 Dependency Graph

```
Phase 10.0 (Foundation: Models + OVERVIEW + Gateway)
  └── Phase 10.1 (Statements + Calculator)
        └── Phase 10.2 (UI: Asset Detail Page)
              └── Phase 10.3 (Crypto Fundamentals)
```

All phases are sequential — each builds on the previous.

### Design Corrections (Apply During Phase 10.2)

The Stitch designs have elements that must be adjusted during implementation:

1. **Remove** "Analyst Verdict" section from tooltip (prescriptive language — regulatory risk)
2. **Remove** "View Full Report →" button from tooltip (implies premium product)
3. **Remove** "Historical PE Trend" chart from tooltip (v2 feature)
4. **Omit** sector averages ("Tech avg: 31.2") from metric cards (no data source in v1)
5. **Fix** "TTM BASIS" label → "ANNUAL BASIS" in statements tab when showing fiscal years
6. **Omit** "View Historical Charts" and "Adjust for Inflation" links (v2 features)
7. **Use FY2024** (not FY2025) as most recent year in fixtures/implementation
8. **Make GAAP label dynamic**: US → "US GAAP", international → "as reported"

---

### Phase 10 Files Summary

| New Files (~25)                                     | Modified Files (~12)                              |
| --------------------------------------------------- | ------------------------------------------------- |
| `db/migrate/..._create_financial_statements.rb`     | `app/controllers/market_controller.rb`             |
| `app/gateways/coingecko_gateway.rb`               |
| `db/migrate/..._create_asset_fundamentals.rb`       | `config/routes.rb`                                |
| `db/migrate/..._add_fundamentals_synced_at.rb`      | `config/initializers/data_sources.rb`             |
| `app/models/financial_statement.rb`                 | `config/initializers/event_subscriptions.rb`      |
| `app/models/asset_fundamental.rb`                   | `config/recurring.yml`                            |
| `app/domain/metric_definitions.rb`                  | `db/seeds.rb`                                     |
| `app/domain/fundamental_calculator.rb`              | `app/views/market/index.html.erb`                 |
| `app/domain/fundamental_presenter.rb`               | `app/views/dashboard/_watchlist_table.html.erb`   |
| `app/gateways/fundamentals_gateway.rb`              | `app/domain/metric_definitions.rb` (Phase 10.3)  |
| `app/gateways/alpha_vantage_gateway.rb`             |                                                   |
| `app/jobs/sync_fundamental_job.rb`                  |                                                   |
| `app/jobs/sync_all_fundamentals_job.rb`             |                                                   |
| `app/use_cases/market/load_asset_detail.rb`         |                                                   |
| `app/events/asset_fundamentals_updated.rb`          |                                                   |
| `app/events/financial_statements_synced.rb`          |                                                   |
| `app/event_handlers/log_fundamentals_update.rb`     |                                                   |
| `app/event_handlers/recalculate_fundamentals_*.rb`  |                                                   |
| `app/event_handlers/broadcast_fundamentals_*.rb`    |                                                   |
| `app/views/market/show.html.erb` + partials         |                                                   |
| `app/javascript/controllers/metric_tooltip_*.js`    |                                                   |
| `spec/` (12+ spec files)                            |                                                   |

---

## Post-Phase 10 Considerations (v2)

These are explicitly out of scope but documented for future planning:

- **CETES complete:** Banxico gateway, yield calculations, maturity calendar, PortfolioSummary branch
- **News: Watchlist filter** — "From Your Watchlist" filter on /news page
- **Historical F&G chart** — Sparkline/line chart of F&G over 30 days (data already stored)
- **Sentiment-based alerts** — "Alert me when crypto F&G < 20"
- **BulkAssetSync concern** — DRY `SyncBulkCryptoJob` / `SyncBulkBmvJob` into shared behavior
- **TrendScore from real data** — Replace seed-only TrendScores with calculated values from price history
- **Email verification** — Requires `generates_token_for :email_verification` (S-3 from security audit)
- **FMP/Polygon provider swap** — Upgrade from Alpha Vantage when budget allows (FundamentalsGateway abstraction ready)
- **Historical P/E chart** — Line chart of P/E over 5 years (data from FinancialStatement + historical prices)
- **Sector comparison** — Compare asset fundamentals vs sector median (requires sector-level aggregation)

---

## Commit Sequence (All Phases)

### Phase 9 (Completed)

| #   | Phase | Commit Message                                                          | New Specs |
| --- | ----- | ----------------------------------------------------------------------- | --------- |
| 1   | 9.0a  | Add requires_api_key to Integration model                               | +2        |
| 2   | 9.0b  | Add DataSourceRegistry with source metadata                             | +6        |
| 3   | 9.0c  | Add SyncLogging concern for standardized job logging                    | +2        |
| 4   | 9.0d  | Refactor sync jobs to use SyncLogging and DataSourceRegistry            | +0        |
| 5   | 9.0e  | Replace hardcoded admin buttons with registry-driven data sources panel | +0        |
| 6   | 9.1a  | Add FearGreedReading model and migration                                | +8        |
| 7   | 9.1b  | Add crypto and stock Fear & Greed gateways                              | +11       |
| 8   | 9.1c  | Add RefreshFearGreedJob with events and handler                         | +10       |
| 9   | 9.1d  | Display Fear & Greed indices on dashboard                               | +6        |
| 10  | 9.2a  | Add historical price fetch to Polygon and CoinGecko gateways            | +6        |
| 11  | 9.2b  | Add BackfillPriceHistoryJob triggered on asset creation                 | +5        |
| 12  | 9.2c  | Connect sparklines to real price history data                           | +7        |
| 13  | 9.3a  | Add fetch_news method to PolygonGateway                                 | +4        |
| 14  | 9.3b  | Add SyncNewsJob with Polygon news integration                           | +8        |
| 15  | 9.3c  | Enhance news page with infinite scroll, filters, and TradingView widget | +8        |
| 16  | 9.4a  | Add fetch_index_quotes to YahooFinanceGateway                           | +4        |
| 17  | 9.4b  | Add SyncMarketIndicesJob with Yahoo Finance                             | +6        |
| 18  | 9.4c  | Add IPC index, VIX indicator, and live index display                    | +5        |
| 19  | 9.5a  | Add fixed_income asset type with yield and maturity fields              | +3        |
| 20  | 9.5b  | Add fixed income badge and filter in market UI                          | +2        |
|     |       | *Phase 9 Total*                                                         | *~103*    |

### Phase 10 (Pending)

| #   | Phase  | Commit Message                                                       | New Specs |
| --- | ------ | -------------------------------------------------------------------- | --------- |
| 21  | 10.0a  | Add FinancialStatement and AssetFundamental models                   | +10       |
| 22  | 10.0b  | Add MetricDefinitions module with 30+ metric definitions             | +4        |
| 23  | 10.0c  | Add AlphaVantageGateway with OVERVIEW endpoint                       | +6        |
| 24  | 10.0d  | Add OVERVIEW sync pipeline with FundamentalPresenter                 | +10       |
| 25  | 10.1a  | Add financial statement fetch methods to AlphaVantageGateway         | +4        |
| 26  | 10.1b  | Add FundamentalCalculator with all metric formulas                   | +10       |
| 27  | 10.1c  | Add statement sync pipeline with FundamentalCalculator               | +11       |
| 28  | 10.2a  | Add asset detail page with summary tab and metric cards              | +8        |
| 29  | 10.2b  | Add category tabs, statements tab, and navigation links              | +6        |
| 30  | 10.2c  | Add metric tooltip controller with help icon popovers                | +6        |
| 31  | 10.3a  | Enrich CoinGecko gateway with extended market data                   | +3        |
| 32  | 10.3b  | Add crypto-specific metrics with adaptive rendering                  | +7        |
|     |        | *Phase 10 Total*                                                     | *~85*     |
|     |        | **Grand Total**                                                      | **~188**  |

---

## Pending: Security & Infrastructure (from Phase 0-8 audit)

> Items identified during the security audit (Feb 2026) that require infrastructure decisions or external configuration. Carried forward from the original roadmap.

| #   | Item                                | Priority | Description                                                                                                                                                                                                                 | Type           |
| --- | ----------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| S-1 | Kamal proxy SSL end-to-end          | Alta     | Enable `ssl: true` in `config/deploy.yml` proxy, or verify Cloudflare uses **Full (Strict)** mode / Tunnel to encrypt traffic between Cloudflare and the server. Without this, traffic travels unencrypted on the last hop. | Infrastructure |
| S-2 | PostgreSQL backups                  | Alta     | Configure `pg_dump` daily cron job on the server. The Kamal PostgreSQL accessory only mounts a data volume but has no backups. Consider also container health checks and PgBouncer for connection pooling.                  | Infrastructure |
| S-3 | Email verification on registration  | Media    | Implement post-registration email verification using `generates_token_for :email_verification`. Currently accounts activate immediately without confirming email.                                                           | Code (v2)      |
| S-4 | Docker image vulnerability scanning | Baja     | Add `trivy` or `grype` step in CI (`deploy.yml`) to scan the Docker image before deploy. The base image `ruby:3.3.6-slim` may have CVEs in system packages.                                                                 | CI/CD          |

**Note:** S-1 and S-2 are deployment-time decisions (not application code). S-3 is deferred to v2 (listed in "Post-Phase 9 Considerations"). S-4 is a CI pipeline enhancement.

---

## Protocol for Starting Any Phase

1. **Read this ROADMAP.md** — identify which phase and step you're on
2. **Read the source plan** — `PLAN_SENTIMENT.md` (for 9.0-9.1), `PLAN_IMPROVEMENTS.md` (for 9.2-9.5), or `PLAN_METRICS.md` (for 10.0-10.3) for deeper context
3. **Check designs/** — if the phase lists a Stitch prompt, ensure the design exists before implementing the view
4. **Run `bundle exec rspec`** — confirm all specs pass before starting
5. **Implement step by step** — one commit per step, tests included
6. **Run `bundle exec rspec`** after each commit — keep green always
7. **Run `bin/rubocop`** — no offenses

### Commit Convention

- Imperative mood ("Add feature" not "Added feature")
- First line under 70 characters
- One commit per logical step
- Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
