# S2 Adriana Cienfuegos — Data Sources Audit

> **One-liner:** Stockerly has solid coverage for US + crypto, but Mexican investor value is bottlenecked by missing direct Banxico FX rates, no BMV earnings for MX equities, and massively over-provisioned Alpha Vantage at 25 calls/day when it's rarely used.

## State of the Product Through My Lens

Stockerly's architecture is well-designed: proper GatewayChain with CircuitBreaker fallback, explicit rate limiting enforced *before* HTTP calls, and routing logic that handles market-specific quirks (Yahoo for BMV earnings, Finnhub for US). The infrastructure prevents cascading failures and overages.

**The problem is not architecture—it's asset coverage.** Adrian wants to use Stockerly as his primary MXN+USD decision tool, but he's getting:
- BMV quotes ✓ (via Yahoo Finance, no API key)
- BMV fundamentals ✗ (not integrated; Alpha Vantage doesn't cover Mexican stocks)
- MXN spot FX ✗ (hardcoded exchangerate-api.com, not official Banxico rates)
- CETES yields ✓ (Banxico API integrated in #133, but asset creation logic broken; see sync_cetes.rb line 33)
- MX equity earnings ✓ (Yahoo Finance, added in #128)
- MXN-BTC/ETH spot pricing ✗ (CoinGecko only quotes USD pairs; no Bitso integration)
- MX market news ✗ (Polygon + Finnhub only cover US equities; no El Economista or Infosel feed)

This is fixable. My recommendation: **kill the dead weight, patch the CETES bug, and add 2 critical sources.**

## Provider Inventory

| Provider | Capabilities | Coverage | Rate Limit | Cost Model | Notes |
|---|---|---|---|---|---|
| **Polygon.io** | Prices, historical, news, earnings | US stocks, indices | 5 req/min, 500/day | Free tier + paid | Primary for US equities. News + earnings are rarely used; news gateway overlaps with Finnhub. |
| **Yahoo Finance** | Prices, historical, search, earnings | US, MX (BMV), global indices | 2,000/day | Free | Only source for BMV quotes & MX earnings. Zero API key needed. Solid for Adrian's use case. |
| **Alpha Vantage** | Fundamentals (PE, EPS, EBITDA, margins, statements) | US + global (not MX) | 5 req/min, **25/day** | Free tier (bottleneck) | Dangerous: 25 calls/day for all US fundamentals sync. At 100 watched assets, this exhausts in hours. Over-specified. |
| **Finnhub** | Prices, historical, news, earnings, search | US stocks + some intl | 60 req/min, 500/day | Free + paid | Good failover for prices/earnings. News and search usable. |
| **FMP** | Dividends, splits, profiles | US + global (not MX) | 10 req/min, 250/day | Free tier (expensive) | Only used for dividends/splits. 250/day is tight for dividend backfill. |
| **CoinGecko** | Crypto prices, market data, history | 1000+ cryptos (no MXN pairs) | 30 req/min, 10,000/day | Free (demo) + Pro | Excellent coverage. Demo tier fine. Pro tier unused. |
| **Banxico SIE** | CETES auction results | MXN fixed income only | Not documented | Free + token | Integrated but broken: SyncCetesJob creates abstract symbols, each sync overwrites prior week's yield. |
| **ExchangeRate-API** | FX conversion rates | 160+ currency pairs | 10 req/min, 1,500/day | Free tier | Works but not official. Adrian needs Banxico authoritative rates. |
| **CNN (undoc)** | Stock Fear & Greed Index | 1 index value | Unknown | Free (scraping) | Unreliable. No rate limit document. |
| **Alternative.me** | Crypto Fear & Greed Index | 1 index value | ~50 req/day | Free | Stable. Crypto sentiment only. |

## What Delivers Value (3-5 Items)

1. **Yahoo Finance (BMV + US indices + MX earnings)** — 2,000 calls/day, no auth. Cornerstone for Adrian. Covers GENIUSSACV.MX, IVVPESO.MX, IPC index, only source for BMV earnings. Zero integration cost; already live. Routing in SyncEarnings is correct.

2. **Polygon.io (US stock prices)** — 5 req/min, 500/day. Primary source. Circuit breaker prevents cascading. News redundant with Finnhub but not harmful. News deduplication smart (Dice coefficient).

3. **CoinGecko (crypto market data)** — 30 req/min, 10,000/day budget. Excellent fit if Adrian holds BTC/ETH. Market data endpoint richer than simple/price (supply, FDV, ATH). Demo tier sufficient.

4. **Banxico CETES (MXN fixed income yields)** — Free API. Integrated in #133. Correct series IDs (SF43936 for 28D, etc.). Calculation logic for discount price correct. **But:** asset creation wrong (see What Doesn't Work).

5. **FMP (dividends)** — 250 calls/day. Only active for dividend sync. Light traffic. Works.

## What's Missing (3-5 Items, Prioritized by MX Investor Value)

### 1. **Banxico Spot FX Rates (USD/MXN) — HIGH PRIORITY**
- **What's needed:** Official daily USD→MXN from Banxico, not exchangerate-api.com guesses.
- **Why:** Adrian manages USD+MXN portfolio. FX rates affect valuation, margin calls, P&L attribution. Official rates zero-cost, refresh daily at 10:30 AM Mexico City time.
- **Candidate:** Banxico SIE (same token as CETES). Series TC_TC002. Data at `serie/TC_TC002/datos/oportuno`.
- **Cost:** 15 lines gateway method. 1 call/day. Reuse BanxicoGateway. Estimated **2 hours dev**.

### 2. **MXN Crypto Spot Prices (BTC/MXN, ETH/MXN) — MEDIUM-HIGH PRIORITY**
- **What's needed:** CoinGecko only quotes USD. If Adrian holds crypto in MXN-denominated account, Bitso (Mexican exchange) publishes free MXN spot rates.
- **Why:** Direct BTC/MXN more reliable than synthetic (BTC/USD × USD/MXN).
- **Candidate:** Bitso API (free public, no auth). `/api/v3/ticker?book=btc_mxn`.
- **Cost:** New gateway or extend FxRatesGateway. 50 lines. 2 calls/day. Estimated **3 hours dev + testing**.

### 3. **BMV Official Company Fundamentals (PE, EPS, dividend dates) — MEDIUM PRIORITY**
- **What's needed:** Alpha Vantage doesn't cover MX stocks. Yahoo partial but incomplete histories.
- **Candidate sources:**
  - Data.bmv.com.mx (HTML scraping, fragile, free). 20–30 hours for robust scraper.
  - Infosel (paid, not free-tier).
  - Accept gap: keep Alpha for US, use Yahoo for MX. Lower urgency if Adrian's portfolio mostly US.
- **Cost:** Scraping: 4–6 hours POC. Not recommended without strong business need.

### 4. **MX Market Holidays Calendar (BMV + Banxico) — LOW-MEDIUM PRIORITY**
- **What's needed:** Already in model `market_holiday.rb`. Currently hardcoded. Alert rules should respect MX closures.
- **Candidate:** Hardcoded seed data (already done). Or build SyncMarketHolidaysJob for automation.
- **Cost:** 0 (done already). If automating: **2 hours**.

### 5. **MX News Feed (El Economista, Infosel, MarketWatch MX) — LOW PRIORITY**
- **What's needed:** Local news for MX market sentiment. SyncArticles pulls only Polygon + Finnhub (US-centric).
- **Candidate:** El Economista RSS (free, no API). MarketWatch MX (scraping). Infosel (paid).
- **Cost:** RSS parser + dedup. 4–6 hours. Low ROI.

## What Doesn't Work (3-5 Items)

### 1. **Alpha Vantage Severely Under-Provisioned (25 calls/day) — CRITICAL**
- **Issue:** `sync.rake` line 16: `daily_call_limit: 25`. At 100 watched assets, single full sync exhausts budget immediately.
- **Evidence:** AlphaVantageGateway is *only* FundamentalsGateway. SyncAllFundamentalsJob is *only* fundamentals job.
- **Impact:** Fundamentals don't sync in production. Adrian sees stale PE, EPS, EBITDA.
- **Fix options:**
  - **A:** Remove Alpha; subscribe FMP paid (~$100/mo, 250+ calls/day).
  - **B:** Smart caching: weekly sync high-priority assets only (saves 80%). 6 hours dev.
  - **C:** Disable fundamentals for now.
- **Recommendation:** Option A (FMP paid) or B (caching + Alpha as fallback).

### 2. **CETES Sync Creates Abstract Assets, Not Lots — BUG**
- **Issue:** `sync_cetes.rb` line 33: `Asset.find_or_initialize_by(symbol: "CETES_#{term}D")` creates *one* asset per term. Each auction overwrites prior week's yield.
- **Evidence:** Comment in lines 27–31 acknowledges this. yield_rate is per-asset, not per-auction.
- **Impact:** Adrian tracking CETES sees *latest* auction yield, not his specific lot's yield. Cost basis lost week-to-week.
- **Fix:**
  - Create per-auction assets (CETES_28D_20260521, etc.) — tedious.
  - Add auction_date + original_yield to Position — better, 3–4 hours schema work.
  - Accept limitation, document that yields are *live* rates.
- **Recommendation:** Document limitation. If Adrian serious about CETES, implement schema change.

### 3. **Polygon News Gateway Redundant + Expensive — WASTE**
- **Issue:** Both Polygon + Finnhub have news. DataSourceRegistry registers `:polygon_news` (500 calls/day). Dedup in SyncArticles makes it wasted.
- **Evidence:** data_sources.rb line 93. GatewayChain.for_capability(:news) returns Polygon first; Finnhub is dead fallback.
- **Impact:** 500 calls/day wasted on redundant news.
- **Fix:** Remove `:polygon_news` registration. Use Finnhub only. Reduce Polygon limit 500→250. Estimated **1 hour**.
- **Recommendation:** Delete Polygon news. Redeploy 500 calls/day to other needs.

### 4. **FX Rates Gateway Hardcoded to ExchangeRate-API — Not Official**
- **Issue:** `fx_rates_gateway.rb` only talks to exchangerate-api.com (free). Adrian needs Banxico official rate (published 10:30 AM Mexico City, free, 100% authoritative).
- **Evidence:** Base URL hardcoded. No preference logic.
- **Impact:** Adrian's FX valuation drifts 0.5–1.0% daily from official (exchangerate-api uses ECB + market averages, not Bank of Mexico).
- **Fix:** Extend FxRatesGateway to query Banxico (series TC_TC002) for USD/MXN. Keep exchangerate-api for other pairs. Routing: if base=="USD" && target=="MXN" then banxico else exchangerate-api. **2 hours**.
- **Recommendation:** High priority for Adrian's trust.

### 5. **No Rate Limiter on Yahoo Finance — RISK**
- **Issue:** sync.rake line 13: `max_requests_per_minute: nil`. RateLimiter returns Success if nil. Daily 2,000 limit tracked but no minute throttle.
- **Evidence:** rate_limiter.rb line 25 returns early if nil.
- **Impact:** If sync hammers Yahoo with 2,000 calls in 1 minute, anti-bot detection blocks Stockerly IP. No fallback.
- **Fix:** Add `max_requests_per_minute: 50` to spread load. Adjust sync job scheduling (stagger). **1 hour**.
- **Recommendation:** Essential before production scale.

## Top 3 Recommendations to Unlock Value

### 1. **Fix Banxico Data Stack for Adrian's MXN+USD Needs (6 hours, $0 cost)**
**What to do:**
- Extend BanxicoGateway: add `fetch_fx_rate()` for USD/MXN (series TC_TC002, same token).
- Register `:banxico_fx` in data_sources.rb. Route FX refresh to Banxico first, fallback to ExchangeRate-API.
- Fix CETES sync: document live auction rates. If Adrian buys frequently, add schema for per-position original_yield (bonus 4 hours).

**Why:** Fixes Adrian's primary blind spot (official MXN rates). Leverages Banxico integration already in place. Zero marginal cost.

**Unlocks:** Accurate MXN portfolio valuation. Proper CETES cost basis. Trust in Stockerly for Mexico.

### 2. **Audit + Right-Size API Budgets (4 hours, $0–100/mo cost impact)**
**What to do:**
- Reduce Polygon 500→250 (news redundant).
- Remove `:polygon_news` registration (Finnhub covers).
- Alpha Vantage: choose FMP paid (~$100/mo) OR smart caching (weekly, high-priority only, saves 80%) OR disable.
- Add minute throttle to Yahoo: `max_requests_per_minute: 50`.

**Why:** Production discipline. Real load means real risk. Prevent API blocks, budget overages, silent failures.

**Unlocks:** Predictable API spend. Reliability at scale. Clean sheet for future providers.

### 3. **Add Bitso MXN Crypto Pricing (3 hours, ~$0 cost)**
**What to do:**
- Create CoingeckoMXNGateway or extend FxRatesGateway for Bitso API (`/api/v3/ticker?book=btc_mxn` + eth_mxn).
- Register `:bitso_crypto_mxn`. Capability: `[:prices]`.
- Route "BTC/MXN" to Bitso first, fallback to CoinGecko USD + Banxico FX.

**Why:** Direct MXN pricing 10x cleaner than synthetic. Bitso free, no auth. High perceived value for Mexican investor.

**Unlocks:** Native MXN crypto portfolio valuation. Demonstrates Stockerly understands Mexican investor flows.

---

## Numbers Summary

| Provider | Budget/Day | Used (Est.) | Utilization | Risk |
|---|---|---|---|---|
| Polygon | 500 | 150–200 | 30–40% | Yellow (news redundant) |
| Yahoo | 2,000 | 200–300 | 10–15% | Yellow (no minute throttle) |
| Alpha Vantage | 25 | 0–5 | 0–20% | Red (under-provisioned) |
| Finnhub | 500 | 50–100 | 10–20% | Green |
| FMP | 250 | 20–50 | 8–20% | Green |
| CoinGecko | 10,000 | 10–20 | <1% | Green |
| Banxico | Unknown | 4–10 | Low | Green |
| ExchangeRate | 1,500 | 1 | <1% | Green |

**Total daily:** ~400–700 calls across ~14K available budget. Room for growth—but Alpha Vantage is a landmine.

---

## Final Take

Stockerly's infrastructure is sound. GatewayChain + CircuitBreaker mature. Rate limiting happens early. Adrian's architecture risk is *low*.

**Product-market fit for Mexican investors is *incomplete*.** Gaps aren't architectural—they're sourcing. Add Banxico FX rates, fix CETES bug, right-size Alpha Vantage, and Stockerly becomes the obvious primary tool for Adrian's MXN+USD portfolio.

Start with **Recommendation 1** (Banxico FX + CETES fix). Highest signal-to-effort. Directly addresses Adrian's stated need: "integrating other data sources or analysis to increase the product's value."
