# Market data providers audit (2026-08)

> Research run to decide **which provider owns which role** in Stockerly's `MarketData` context, and
> to establish what each free tier actually permits. Companion to
> [competitive-trackers-2026-08.md](competitive-trackers-2026-08.md).
>
> **Method.** Two axes. *Supply*: four parallel agents, each probing a provider cluster against live
> docs and, where possible, live endpoints. *Demand*: the seven `.pen` flows in [`design/`](../../design),
> read for what each drawn block actually requires. Every gateway claim below is a `file:line` in this
> repo; every provider claim carries a source or is marked unverified.
>
> **Expert panel** (per [experts.md](experts.md)): S2 Adriana Cienfuegos (data engineering, rate
> limits), C1 Lucía Ramírez (Mexican financial domain), S5 Ileana Voinea (legal/compliance),
> C6 Esther Mwangi (scope).

---

## 1. Per-provider findings

**DataBursatil** — Mexican market (BMV + BIVA), token-authenticated, explicitly non-profit. The only
sanctioned MX source found. Covers what nothing else in the stack covers: **financial statements for
BMV issuers** (`get_financieros`, by quarter), **intraday bars** at 1m/5m/1h, **batch quotes up to 50
issuers**, the IPC index, TIIE rates, individual trades by time window, and symbol-anchored MX news.
Quota is **200,000 credits/month where one credit is 1 KiB transmitted — not one request** — resetting
on the 1st at 00:01 CDMX. ⚠️ Endpoint shapes below come from a community MCP server's README
(`angel7i/databursatil-mcp`), not the vendor's docs, which return **403** to automated fetching; its
**terms of service are unread**.

**Banxico SIE** — the Mexican backbone and the least replaceable provider. Publishes the FIX in **two
series carrying the same numbers one banking day apart**: `SF43718` (*fecha de determinación*) and
`SF60653` (*fecha de liquidación*). The FIX is determined on day D from quotes settling D+2, announced
from 12:00 on D, published in the DOF the next banking day; obligations settle at the rate published
*"el día hábil bancario inmediato anterior"*. **For valuing a trade at its own date, `SF60653` is
correct** — it makes the lookup a direct `series[trade_date]` with no banking-day arithmetic and it
carries forward across weekends and holidays, where `SF43718` is simply absent. Allows **20 series per
request**. Terms are the friendliest in the stack: general reproduction against source + a
banxico.org.mx URL. *C1 Lucía: the FIX is the settlement reference — it reconciles to broker statements
and CFDIs and reproduces forever; a market mid-rate does neither. It is a valuation basis, not the rate
Adrian actually converted at.*

**Alpaca** — free Basic plan's **historical** endpoint serves **SIP consolidated tape**, subject only to
a 15-minute recency restriction: *"For historical queries, the `end` parameter must be at least 15
minutes old to query SIP data without a subscription."* The IEX-only limit governs the real-time
**stream**, a separate surface. A daily bar is always older than 15 minutes, so **the official
consolidated close is free** — but only if the request sends `feed=sip`; the default resolves to `iex`
for a Basic key and silently degrades the data. 200 req/min, history since 2016. A **paper account opens
globally with an email** — no funding, no KYC, no US residency — and issues the same keys the data
endpoints use. **Zero BMV coverage.**

**Yahoo Finance** (unofficial `query1`/`query2`) — irreplaceable and unsanctioned at once. Verified live:
`WALMEX.MX` returns **390 × 1m bars and 78 × 5m bars**, in MXN, keyless, no crumb; lookback 1m = 7d,
5m = 60d; BMV delay is 20 minutes. `events=div,split` yields **41 WALMEX dividends and 3 splits back to
2003** — BMV corporate actions available from no other configured source. **The risk is concentration and
it is already biting:** direct calls from a datacenter IP returned **429 on every Yahoo path, first
request**, while Google and FMP were fine. Production runs on Hetzner. Two of its surfaces are already
dead: `/v10/quoteSummary` returns `Invalid Crumb` and `/v7/quote` returns `401`.

**Alpha Vantage** — 25 calls/day free, 20+ years of history, free dividends/splits, free USD/MXN, and
**unlimited requests granted to verified open-source projects**. ToS is silent on caching and
redistribution. Reported to cover BMV via a `.MEX` suffix — unverified.

**Polygon.io → Massive.com** — **rebranded 2025-10-30**; `polygon.io` now 301s to `massive.com` and
`api.polygon.io` is announced for phase-out. Market Data Terms rewritten 2025-08-28, after our gateway
was written. Free tier is 5 req/min and 2 years of history. Index quotes (SPX/NDX/DJI) and earnings are
now **separate paid products**.

**Finnhub** — 3,600 calls/day free. Its OpenAPI blob lists 116 endpoints: **32 free, 84 premium**.
`/stock/candle` is premium — free keys get **403**. Free news, earnings and search remain.

**CoinGecko** — 10k calls/month, 100/min, and a **hard 365-day history wall** on the free tier
(`error_code 10012`). **Quotes MXN natively.** Redistribution prohibited.

**FMP** — free tier is 250/day, EOD, **US-only**; Mexico requires Ultimate at $149/mo. Its `/api/v3/`
routes are now **"Legacy", gated to accounts created before 2025-08-31** — so the gateway works on an
existing key and **403s for any new self-hoster**.

**ExchangeRate-API** — historical data is paywalled and self-described as unsuitable for settlement.
Superseded by Banxico for USD/MXN.

**alternative.me** (crypto Fear & Greed) — free, keyless, **3,125 daily points back to 2018-02-01**,
currently unused.

**CNN Fear & Greed** (`production.dataviz.cnn.io`) — **dead**. A live probe returns **HTTP 418 "I'm a
teapot. You're a bot."** on every User-Agent including the gateway's own; the block is IP-reputation
based and Hetzner is in the same class. Undocumented, unlicensed, no sanctioned equivalent.

**SiftingIO** — **evaluated and rejected**, recorded so it is not re-litigated. Per-market pricing
(stocks, forex and crypto bought separately — ~$261/mo Builder, ~$678/mo Pro for this use case), **1
month of history on the free tier**, no Mexican coverage, and no track record (10 repos dated
May–Aug 2026, maximum 1 star). *C6 Esther: it sells unification and charges separately for each thing it
unifies.*

---

## 2. Comparison

| Provider | Free limit | History | Intraday | MX coverage | Redistribution |
|---|---|---|---|---|---|
| **DataBursatil** | 200k credits/mo (**1 KiB = 1 credit**) | ? | ✅ 1m/5m/1h | ⭐ **BMV + BIVA + statements** | ⚠️ unread |
| **Banxico** | generous, blocks token **1 full day** on breach | deep | n/a | ⭐ FIX, CETES, TIIE | ✅ with attribution |
| **Alpaca** | 200 req/min | since 2016 | ✅ but ≥15 min old | ❌ none | ❌ |
| **Yahoo** | none stated — **429 from datacenter IPs** | deep | ✅ 1m (7d) / 5m (60d) | ⭐ `.MX`, `^MXX`, div/split | ⚠️ unofficial |
| **Alpha Vantage** | 25/day — **unlimited for OSS** | 20+ yr | premium | reported `.MEX` | silent |
| **Massive** (ex-Polygon) | 5 req/min | 2 yr | ❌ free | ❌ | ❌ |
| **Finnhub** | 3,600/day | premium candles | ❌ free | ❌ | ❌ |
| **CoinGecko** | 10k/mo, 100/min | **365 d wall** | — | quotes MXN | ❌ |
| **FMP** | 250/day | EOD | ❌ | $149/mo | ❌ |
| **alternative.me** | free, keyless | since 2018 | n/a | n/a | — |
| **CNN** | **dead (418)** | — | — | — | ❌ |

---

## 3. Terms of service — the two build-changing findings

*S5 Ileana: this column produced conclusions no amount of endpoint cataloguing would have surfaced.*

**Redistribution is prohibited by Alpaca, CoinGecko, Massive, Finnhub and FMP** — several explicitly
including *derived works*. Banxico permits it with attribution; Alpha Vantage is silent; DataBursatil is
unread.

1. **A seeded demo must be synthetic.** The 2.0 vision requires seeded data to fix the empty first run,
   and an open-source repo redistributes by construction. No real market data can ship in it.
2. **Multi-key rotation is prohibited** by four providers. Rotating several keys of the *same* provider
   to stretch its free tier is the prohibited conduct regardless of naming; falling back to a *different*
   provider (what `GatewayChain` already does) is unaffected. The pool only ever bought Alpha Vantage
   25 → 50 calls/day, which is not worth account termination in a product other people run.

One reading we **disagree** with: Massive §1 (*"you may not use the Market Data to build an application
intended for use by end users other than you"*) was read as forbidding the self-hosting model. Each
self-hoster brings **their own key** and consumes data for themselves, which is precisely not serving
other end users. The clause bites the demo seed, not the distribution model.

---

## 4. Audit of the current gateways

Findings against `app/contexts/market_data/gateways/` and its callers, 2026-08-26.

| # | Finding | Location |
|---|---|---|
| 1 | Wrong FIX series — uses `SF43718` while the adjacent comment states the goal is what a broker settles against | `banxico_gateway.rb:13-15` |
| 2 | FIX absent before ~12:00 CDMX returns `:not_found` — indistinguishable from an outage | `banxico_gateway.rb:135` |
| 3 | **No `RateLimiter`** — the only gateway without one, against a provider that blocks the token for a full calendar day and serves both FX and CETES | `banxico_gateway.rb` |
| 4 | `fetch_all_terms` makes 4 calls for one CETES curve; Banxico allows 20 series per request | `banxico_gateway.rb` |
| 5 | `/v7/quote` 401 makes `fetch_batch_quotes` fall back to **one chart call per symbol** — a ~20× amplifier aimed at the endpoint that rate-limits, from an IP class that already 429s | `yahoo_finance_gateway.rb:51-59` |
| 6 | `/v10/quoteSummary` returns `Invalid Crumb`, so `fetch_earnings` — the only BMV earnings source — returns nothing | `yahoo_finance_gateway.rb:118` |
| 7 | `fetch_chart` hardcodes `range=1d, interval=1d` and returns only `meta`, not the series; `bars.uniq! { |b| b[:date] }` would collapse any intraday series | `yahoo_finance_gateway.rb`, `:355` |
| 8 | `/stock/candle` is premium — 403 on free keys — and is tagged `:gateway_error`, so `CircuitBreaker` retries a permanent denial forever | `finnhub_gateway.rb` |
| 9 | `fetch_earnings` calls the retired `/vX/reference/tickers/…/earnings` | `polygon_gateway.rb:83` |
| 10 | `BASE_URL` hardcoded to a host announced for retirement | `polygon_gateway.rb:8` |
| 11 | Hardcodes `vs_currency=usd` in three places although CoinGecko quotes MXN natively | `coingecko_gateway.rb` |
| 12 | Unsourced `# Rate limit: ~50 req/day` throttling a source that is not throttled | `crypto_fear_greed_gateway.rb:4` |
| 13 | Maps only 429, so the 418 block surfaces as a generic error | `stock_fear_greed_gateway.rb:16-17` |
| 14 | `data_source` is computed per fetch and **discarded on persist** — `asset_price_histories` and `market_index_histories` have no `source` column | `gateway_chain.rb:33` |
| 15 | Registry is decorative on the main path: `for_capability` has two call sites; prices route through a hardcoded `case` | `sync_single_asset_job.rb:63` |
| 16 | `fx_rates` registers capability `%i[fx]` while `banxico_fx` registers `%i[fx_rates]` — two names for one capability, which could never share a chain | `config/initializers/data_sources.rb` |
| 17 | The quota budget counts **successful log lines, not API calls**: a statements sync spends 3 and logs 1; failures consume quota and are filtered out; and a prefix mislabel is the only reason statements consumption is counted at all | `fundamentals_budget.rb`, `sync_statements_job.rb:31,33` |
| 18 | `DAILY_BUDGET = 25` duplicated as a literal instead of reading `FundamentalsBudget::DAILY_LIMIT` | `sync_all_statements_job.rb:8` |

**The pattern under all of it:** every one of these surfaces as the same generic `:gateway_error`.
Nothing distinguishes *no entitlement* from *rate limited* from *endpoint retired* from *before
publication time* from *blocked by IP reputation*. *S2 Adriana: that is the finding — a chain that
cannot tell a permanent denial from a transient failure will retry the denial and starve the retry.*

---

## 5. Role assignment

| Capability | Primary | Fallback |
|---|---|---|
| BMV prices (EOD) | DataBursatil | Yahoo |
| BMV intraday / provisional | DataBursatil | Yahoo `chart` |
| BMV fundamentals + statements | DataBursatil | — *(impossible before)* |
| IPC / MX indices | DataBursatil | Yahoo |
| MX rates (TIIE) | DataBursatil | — |
| MX news | DataBursatil (`get_cables`) | — |
| US prices (EOD, confirmed) | Alpaca (SIP, `feed=sip`) | Finnhub |
| US intraday / provisional | Yahoo `chart` | — |
| US fundamentals + statements | Alpha Vantage | — |
| US news + earnings | Finnhub | Massive *(retiring)* |
| Crypto | CoinGecko *(request MXN)* | — |
| FX — valuation basis | **Banxico FIX `SF60653`** | — |
| CETES | Banxico | DataBursatil `guber`? |
| Sentiment — crypto | alternative.me | — |
| Sentiment — stocks | **none — CNN is dead** | — |

Nothing here is redundant. Two rows that were single points of failure gained a fallback: **Alpaca
replaces Massive** for confirmed US closes, and **DataBursatil ends BMV's sole dependency on an
unsanctioned endpoint**.

---

## 6. Not verified

- **DataBursatil, almost entirely** — its site and docs return 403 to automated fetching, so §1's
  endpoint shapes and credit model come from a community MCP README and search snippets. **Its terms
  are unread.** The account exists; this is a docs read, not further research.
- Whether Yahoo's endpoints work **from the production host**. Everything reports as
  `:gateway_error`, so a live outage would be invisible.
- Whether Alpha Vantage's open-source grant applies to Stockerly. It would remove the 25-call/day
  budget the tier ladder is built to ration.
- Alpha Vantage's BMV coverage via `.MEX` — reported, not probed.
- Alpaca's earnings and news coverage.
- Whether any **sanctioned alternative to Yahoo** exists for `.MX` beyond DataBursatil. The agent
  tasked with that research died mid-run and returned nothing.
