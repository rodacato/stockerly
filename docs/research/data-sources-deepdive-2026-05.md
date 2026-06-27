# Data sources deep-dive + TradingView free-widget evaluation

> Issue [#175](https://github.com/rodacato/stockerly/issues/175). Research-only — no code changes.
> Authored 2026-06-27 from a static read of the registry, gateways, jobs, and views.

## Method & hard caveat

This audit is built from the **code**, not from production telemetry. Issue #175 asks for "actual call volume / error rate last 30 days from `SystemLog`" — that data lives in the production database and is **not reachable from the dev environment**. No runtime numbers are invented here. Every cell that needs production data is marked **⚠️ prod** and the exact query to fill it is in [§1.3](#13-how-to-fill-the-prod-cells). Provider roles, rate-limit *mechanisms*, and wiring are read directly from source and are reliable.

Source of truth read: `config/initializers/data_sources.rb` (registry), `app/contexts/market_data/gateways/*`, the `Sync*`/`Refresh*` jobs in `app/jobs/`, `app/shared/domain/{data_source_registry,rate_limiter}.rb`, `app/models/system_log.rb`, and the `market`/`dashboard` views.

---

## Part 1 — Provider health audit

### 1.1 What's actually wired

The registry (`DataSourceRegistry`) holds **13 registrations across 10 providers**. Registration order within a capability defines fallback priority — first registered = primary. Numeric rate limits are **not** in code; they live per-row in the `integrations` table (`max_requests_per_minute`, `daily_call_limit`), enforced by `RateLimiter.check!`.

| Provider | Registered as | Capabilities | Role | Notes from code |
|---|---|---|---|---|
| **Polygon.io** | `polygon_stocks`, `polygon_news`, `polygon_earnings` | prices, historical, indices, news, earnings | **Primary** US stocks; sole registered news + earnings | 3 registrations, one gateway. Heaviest surface. |
| **Finnhub** | `finnhub_stocks` | prices, historical, search, news, earnings | **Secondary** US stocks (fallback) | Declares news + earnings but Polygon is registered first for both → Finnhub's news/earnings only fire on Polygon circuit-open. |
| **CoinGecko** | `coingecko_crypto` | prices, historical, market_data | **Primary** crypto | `RateLimiter`-gated. |
| **Yahoo Finance** | `yahoo_bmv`, `yahoo_indices` | prices, historical, search, indices | **Primary** BMV / MX stocks + indices | The only MX-equity price source. Load-bearing for the MX thesis. |
| **Alpha Vantage** | `alpha_vantage_fundamentals` | fundamentals | Fundamentals | Free tier ≈ 25 calls/day; signals limit as **HTTP 200 + `"Note"` key**, not 429 (`alpha_vantage_gateway.rb:5`). Brittle at portfolio scale. |
| **FMP** | **not registered** ⚠️ | (fundamentals, splits, dividends in practice) | Fundamentals/splits/dividends | **Anomaly:** called directly by `SyncFundamentalJob`, `SyncSplitsJob`, `SyncDividendsJob` but absent from the registry → invisible to admin integration health, the capability-fallback chain, and the connectivity test. |
| **Banxico** | `banxico_cetes` | cetes | CETES (MX fixed income) | Official source. Gains `fx` once #177 lands. |
| **ExchangeRate-API** | `fx_rates` | fx | **Primary** USD/MXN today | To be **demoted to fallback** by #177 (Banxico TC_TC002 becomes primary). |
| **CNN** | `stock_fear_greed` | sentiment | Stock Fear & Greed | Scraped index; no auth. |
| **Alternative.me** | `crypto_fear_greed` | sentiment | Crypto Fear & Greed | Free, ≈50 req/day (`crypto_fear_greed_gateway.rb:4`). |

### 1.2 Structural findings (no runtime data needed)

1. **Fundamentals is served by two providers at once.** Alpha Vantage is the *registered* fundamentals source, but `SyncFundamentalJob` uses **FMP** directly. Two providers, one capability, one of them off-registry. This is the single biggest consolidation opportunity. → **Pick one** (FMP has the saner free tier), register it, retire the other from fundamentals.

2. **FMP bypasses the registry pattern entirely.** It is the only provider in active use that isn't registered. It still calls `RateLimiter.check!`, but it has no admin visibility, no connectivity test, and isn't part of any documented fallback. → **Register FMP** (capabilities `[:fundamentals, :corporate_actions]`) or formally document why it's exempt.

3. **Redundant news.** `polygon_news` is the registered news source; Finnhub also declares `news`. Adriana's prior audit flagged Polygon news as redundant. If Finnhub's news is adequate, **remove `polygon_news`** and let Finnhub own news — one fewer Polygon surface against its rate budget.

4. **Indices declared three ways.** `polygon_stocks` (indices), `yahoo_indices`, and `yahoo_bmv` (indices) all claim the `indices` capability. Likely fine as graceful fallback, but worth confirming only one actually runs in the green path.

5. **Alpha Vantage's 25/day cap is structurally too small** for per-asset fundamentals across even a 20-symbol portfolio, and its 200+`"Note"` failure mode is a silent-failure trap. This reinforces finding #1.

### 1.3 How to fill the ⚠️ prod cells

Run in production (`bin/kamal console`) to score each provider on real 30-day usage. `SystemLog` carries `module_name` + `task_name` + `severity`; provider names match the `PROVIDER` constants / registry `integration_name`.

```ruby
window = 30.days.ago

# Call volume + error rate per module over the window
SystemLog.where("created_at >= ?", window)
         .group(:module_name, :severity)
         .count
# => { ["MarketData::Gateways::PolygonGateway", "success"] => N, [..., "error"] => M, ... }

# Error rate per module
SystemLog.where("created_at >= ?", window).group(:module_name).group(:severity).count

# Configured limits actually in the DB (the numbers the code reads):
Integration.pluck(:provider_name, :max_requests_per_minute, :daily_call_limit, :active)
```

Fill the scorecard's **Calls/30d**, **Error %**, and **Limit** columns from this output, then the Keep/Remove/Replace call becomes data-backed rather than structural.

### 1.4 Keep / Remove / Replace (structural recommendation, pending §1.3 data)

| Provider | Recommendation | Rationale |
|---|---|---|
| Polygon.io (prices/historical) | **Keep** | Primary US equities; core. |
| Polygon.io (news) | **Remove** (candidate) | Redundant with Finnhub news; frees Polygon budget. Confirm Finnhub news quality first. |
| Polygon.io (earnings) | **Keep** | Sole registered earnings source. |
| Finnhub | **Keep** | Real fallback for prices; promote to news owner if Polygon news is removed. |
| CoinGecko | **Keep** | Primary crypto, no alternative wired. |
| Yahoo Finance | **Keep** | Only MX-equity + indices source. Load-bearing. |
| Alpha Vantage | **Replace** | Fold fundamentals into FMP; 25/day + silent-Note failure isn't worth a second fundamentals provider. |
| FMP | **Keep + register** | Already doing the real fundamentals/corporate-actions work; just needs to enter the registry. |
| Banxico | **Keep** | Official; expanding via #177. |
| ExchangeRate-API | **Keep as fallback** | Demoted by #177, retained for non-USD/MXN pairs and Banxico-circuit-open. |
| CNN F&G | **Keep** | Cheap sentiment signal. |
| Alternative.me | **Keep** | Cheap crypto sentiment. |

---

## Part 2 — TradingView free widgets

### 2.1 Reality check: the flagship is already shipped

`app/views/market/_tradingview_chart.html.erb` already embeds the **TradingView Advanced Chart** widget on `/market/:symbol`, lazy-loaded via an IntersectionObserver Stimulus controller (`data-controller="tradingview"`). So the highest-value widget the issue speculated about ("embed Advanced Chart on /market/:symbol") is **done**.

Two issues with the existing embed, found in passing:
- **Hardcoded `data-tradingview-theme-value="light"`** (line 5) — the widget stays light-themed even in dark mode. Real visual bug.
- The partial still carries pre-Lumen chrome (`bg-white dark:bg-slate-900` …) — picked up by the #174 Lumen sweep (PR #233).

So Part 2 is really: *given Advanced Chart is in, which of the remaining free widgets earn a slot?*

### 2.2 Widget evaluation

TradingView's free widgets are copy-paste `<script>`/iframe embeds, no API key. **Attribution is mandatory on the free tier** — the TradingView logo/link stays; removing it requires a paid arrangement. Their look does not match Lumen (their palette, their type), so each embed is a brand-coherence cost.

| Widget | Could replace / augment | Cost | Verdict |
|---|---|---|---|
| **Advanced Chart** | `/market/:symbol` main chart | Already embedded | ✅ **In** — fix the dark-theme bug. |
| **Symbol Overview** | `_price_chart` mini sparkline on `/market/:symbol` | Low (embed) | ⚠️ **No** — Advanced Chart already covers the symbol; a second TV chart on the same page is noise. |
| **Economic Calendar** | New surface; no current equivalent | Low | ✅ **Go (trial)** — genuinely additive for an MX investor tracking Banxico/Fed dates; nothing in-app does this. Brand cost acceptable on a dedicated `/calendar` or a dashboard tab. |
| **Ticker Tape** | Top-of-dashboard running ticker | Low | ⚠️ **Maybe** — cheap "alive" signal, but it's the loudest brand clash (scrolling TV-styled strip above Lumen content). Renata-gated. |
| **Market Overview** | Could augment `/dashboard` indices block | Low | ⚠️ **No** — overlaps the existing `_market_status` + indices; would duplicate data in a non-Lumen skin. |
| **Screener** | No current equivalent | Low | ❌ **No** — screening isn't a JTBD for the single-portfolio MX user; out of scope per vision. |
| **Crypto Heatmap** | Dashboard crypto glance | Low | ❌ **No** — niche; portfolio is MXN/USD-equity-first. |

### 2.3 Trade-off summary

- **Performance:** each TV widget pulls their script bundle; keep the IntersectionObserver lazy-load pattern already used for Advanced Chart for any new embed.
- **Brand:** every widget is a Lumen exception. Advanced Chart earns it (charting is hard to out-build); a ticker tape does not.
- **Attribution:** non-negotiable on free tier — fine for an open-source non-commercial product, but it's third-party branding on the page; note it in any embed.

---

## Top-3 recommended changes

1. **Consolidate fundamentals onto FMP and register it.** Retire Alpha Vantage's fundamentals role (25/day + silent-Note failure), make FMP a first-class registry entry. Removes a redundant provider and closes the off-registry anomaly. **Effort: ~3-4h.**
2. **Fix the TradingView Advanced Chart dark-theme bug.** Drive `theme` from the active color scheme instead of hardcoded `"light"`. Small, high-visibility. **Effort: ~1h.**
3. **Trial the Economic Calendar widget** as the one genuinely additive TradingView surface (Banxico/Fed dates), behind the existing lazy-load pattern, on a dedicated route or dashboard tab. **Effort: ~2-3h.**

Runner-up: remove `polygon_news` in favour of Finnhub news once §1.3 confirms Finnhub news volume/quality (frees Polygon's rate budget).

---

## S13 issue candidates (to file at S13 open)

- **[chore] Register FMP + retire Alpha Vantage fundamentals** — consolidation; depends on §1.3 data confirming FMP coverage.
- **[fix] TradingView Advanced Chart ignores dark mode** — `theme` hardcoded `light` in `_tradingview_chart.html.erb`.
- **[feat] Economic Calendar widget** (trial) — new surface, lazy-loaded, attribution noted.
- **[chore] Run the §1.3 provider scorecard query in prod and fill runtime metrics** — converts this structural audit into a data-backed one; prerequisite for the Remove decisions.
- **[research] Confirm Finnhub news parity before removing `polygon_news`.**

---

## Expert notes

**S2 Adriana (data sources).** "The off-registry FMP is my headline — you can't manage what you can't see. Register it or kill it. And stop paying the Alpha Vantage tax: two fundamentals providers for one capability is exactly the silent waste a 30-day `SystemLog` pass exposes. The scorecard query in §1.3 is the whole point — run it before you remove anything."

**C4 Marisol (Hotwire/Tailwind).** "Every TradingView embed is a `<script>` you can't theme to Lumen. The Advanced Chart already proves the lazy-load Stimulus pattern works — reuse it, don't reinvent. But fix that hardcoded `light` theme; a dark-mode user staring at a white chart is a worse bug than no chart."

**C5 Renata (brand/UX).** "Advanced Chart earns its exception because charting is genuinely hard. A Ticker Tape does not — it's a scrolling billboard in someone else's font sitting on top of our quiet Lumen surfaces. Economic Calendar is the one I'd allow: it serves a real need we don't cover, and it can live on its own route where the brand clash is contained."
