# Market data providers audit (2026-08)

> **Snapshot as of 2026-08-26; annotated 2026-08-27.** The provider probes below have not been
> re-run, and every provider fact is as of that date. **The wiring they describe has since
> changed**, and the sections that were rewritten by that change say so inline:
>
> | What superseded it | Effect on this document |
> |---|---|
> | [ADR-015](../architecture/adr/0015-one-api-key-per-provider.md) | Multi-key rotation retired — §3's finding is now policy, not a proposal |
> | [ADR-017](../architecture/adr/0017-python-bridge-for-yahoo-finance.md) | Yahoo is reached through a Python bridge, not directly; §1's datacenter-IP theory is **disproved** |
> | [#312](https://github.com/rodacato/stockerly/issues/312) | Dividends and splits route by market (Alpaca / bridge); FMP is fundamentals-only and `maintainer_only` |
> | [#318](https://github.com/rodacato/stockerly/issues/318) | Banxico reads `SF60653`, the settlement series |
> | [#319](https://github.com/rodacato/stockerly/issues/319) | The registry routes on market and asset type; §4's finding 15 is closed |
> | [#320](https://github.com/rodacato/stockerly/issues/320) | CoinGecko stays on USD **deliberately**; the CETES curve is one request |
>
> **All eighteen findings in §4 are resolved.** They are kept with their closures because two of
> them turned out to be wrong, and being wrong in an audit is the part worth keeping. The queue
> that tracked them (`market-data-remediation.md`) was deleted once it emptied; what it carried
> and this file did not is folded into §6.
>
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
sanctioned MX source found. **Verified live 2026-08-26** (`redesign/probes/probe.rb`): base
`https://api.databursatil.com`, auth is `?token=` in the query string and **nothing else** — header
auth is rejected. Errors come back as a **map keyed by parameter** (`{"Error": {"concepto": [...]}}`),
which makes failures diagnosable without parsing prose, and **failed requests cost no credits**.

Confirmed working: `/v2/cotizaciones` (batch quotes, `*` series wildcard, returns **BMV and BIVA
separately with their own timestamps**), `/v2/historicos` (EOD, `{"date": [close, importe]}` — **close
and traded amount only, no OHLC**; `concepto` is rejected here), `/v2/intradia` (1m/5m/1h bars),
`/v2/creditos` (reports `disponibles`), `/v2/emisoras` (catalogue incl. `isin`,
`acciones_en_circulacion`, and per-issuer `rango_historicos` / `rango_financieros` / `dividendos`).

**The credit model is measured, not cited: 1 credit = 1 KiB (base 1024), rounded up, out of 200,000
a month.** A 9,791-byte response cost 10 credits. Two consequences the code must respect: querying
the balance **itself costs a credit**, so it has to be cached rather than polled; and `/v2/emisoras`
unfiltered returns **2.23 MB ≈ 2,181 credits — about 1% of the monthly quota in one call**.

**`/v2/emisoras` does take a filter, and this document said otherwise until 2026-09-05
([#379](https://github.com/rodacato/stockerly/issues/379)).** The docs were unreadable during the
August audit — `databursatil.com/docs.html` 403s a bare client — and the conclusion *"no filter
parameter found"* was inferred rather than read. Sending a browser `User-Agent` returns the page.
Two optional parameters: **`letra`**, which *"filtra las emisoras por la letra o palabra completa
ingresada"* and accepts a whole ticker (the docs' own example is `letra=NFLX`), and **`mercado`**,
`local` and/or `global`. Measured: `letra=AC&mercado=local` returned **6,538 bytes ≈ 6 credits**
against the catalogue's 2,181 — **roughly 350× cheaper** — and the row carries `isin`,
`acciones_en_circulacion`, `rango_historicos` and `rango_financieros`. **So `/v2/financieros` is not
blocked by a 2,181-credit catalogue fetch**; one filtered call per issuer answers both the emisora
key and which periods exist. `concepto` selects which fields are returned, making payload size
**caller-controlled**: one field cost 65 bytes against 184 for eleven, a 2.8× difference. No other
provider in the stack has that lever.

⚠️ **Three documented capabilities did not work.** `/v2/indices` answers, but the IPC came back
stamped `2026-06-26` — **two months stale, byte-identical across calls minutes apart** — while
`/v2/cotizaciones` served same-day data, so it cannot replace `^MXX`. `/v1/dividendos` **404s**
although the docs table lists it, and so does `/v2/dividendos`. **`/v2/descargas` with
`archivo=guber` is documented, accepted and served by no date — Q-8 closed 2026-09-05
([#380](https://github.com/rodacato/stockerly/issues/380)).** The docs describe it as *"valuaciones
de instrumentos de mercado de dinero gubernamental mexicano"*, delivered as CSV. The archive name is
not the problem: an invalid one answers *"Solo hay dos opciones disponibles: 'guber' o 'hechos'"*,
while `guber` answers *"La fecha ingresada no esta disponible o no existe"*. The control settles it
— on **2026-09-02, 09-03, 09-04 and 2026-08-28**, `archivo=hechos` returned a 3 MB zip on every one
and `guber` 404'd on every one, **including the date the documentation uses as its own example**
(`2025-06-02`). A documented capability with no file behind it. **`/v2/financieros`'s blocker was
misdiagnosed** — see the `letra` finding above; the emisora key is one cheap filtered call away.

**Banxico SIE** — the Mexican backbone and the least replaceable provider. Publishes the FIX in **two
series carrying the same numbers two banking days apart** — measured 2026-08-26, 663 of 666 points over
2024–2026 match at an offset of exactly two publication days: `SF43718` (*fecha de determinación*) and
`SF60653` (*fecha de liquidación*). The FIX is determined on day D from quotes settling D+2, announced
from 12:00 on D, published in the DOF the next banking day; obligations settle at the rate published
*"el día hábil bancario inmediato anterior"*. **For valuing a trade at its own date, `SF60653` is
correct** — it makes the lookup a direct `series[trade_date]` with no banking-day arithmetic and it
carries forward across weekends and holidays, where `SF43718` is simply absent. Allows **20 series per
request**. Terms are the friendliest in the stack: general reproduction against source + a
banxico.org.mx URL. *C1 Lucía: the FIX is the settlement reference — it reconciles to broker statements
and CFDIs and reproduces forever; a market mid-rate does neither. It is a valuation basis, not the rate
Adrian actually converted at.*

**Alpaca** — **verified live 2026-08-26 against a Basic key.** `feed` **already defaults to `sip`**;
what the free plan loses is recency, not venue — every surface inside 15 minutes returns
`403 {"message":"subscription does not permit querying recent SIP data"}`, identically for
`/v2/stocks/{sym}/bars/latest`, `/v2/stocks/snapshots` and a recent bars window. **So Alpaca serves
confirmed EOD history and cannot serve a current price at all.** `feed=iex` does return a degraded
series — 3% of the volume — in a **response shape identical to SIP with no field naming the feed**.
Daily bars are multi-symbol in one call with `next_page_token` pagination, reach 2016, and
`adjustment=all` yields split-adjusted series natively. `/v1beta1/news` (Benzinga) and
`/v1/corporate-actions` (dividends and splits with `ex_date`, `payable_date`, `record_date`, `rate`)
are both free on Basic. 200 req/min via `X-RateLimit-*`. **No earnings, no indices, zero BMV** — and
an unknown symbol returns `{"bars":{}}` with HTTP **200**, so absence reads as success.

**Yahoo Finance** (unofficial `query1`/`query2`) — irreplaceable and unsanctioned at once. Verified live:
`WALMEX.MX` returns **390 × 1m bars and 78 × 5m bars**, in MXN, keyless, no crumb; lookback 1m = 7d,
5m = 60d; BMV delay is 20 minutes. `events=div,split` yields **41 WALMEX dividends and 3 splits back to
2003** — BMV corporate actions available from no other configured source. **The risk is concentration and
it is already biting:** every request a Ruby HTTP client can construct returns **429, first request**.

⚠️ **This paragraph's diagnosis was wrong and is corrected here.** It attributed the 429 to Hetzner's
datacenter address range. A residential connection returned 429 too, and the crumb bootstrap 429s on
the crumb endpoint itself: the block is on the **TLS fingerprint**, not the IP. Yahoo is now reached
through a Python subprocess whose client presents a browser handshake
([ADR-017](../architecture/adr/0017-python-bridge-for-yahoo-finance.md)), self-capped at 6 req/min and
200/day, and quarantined to the three capabilities no sanctioned provider serves. Two of its surfaces
were already dead and stay dead: `/v10/quoteSummary` returns `Invalid Crumb` and `/v7/quote` returns
`401`.

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
| **DataBursatil** | 200k credits/mo — **1 credit = 1 KiB, measured** | since ~2015 (`historicos`) | ✅ 1m/5m/1h | ⭐ **BMV + BIVA**, close-only EOD | ⚠️ unread |
| **Banxico** | generous, blocks token **1 full day** on breach | deep | n/a | ⭐ FIX, CETES, TIIE | ✅ with attribution |
| **Alpaca** | 200 req/min | since 2016 | ❌ anything <15 min is 403 | ❌ none | ❌ |
| **Yahoo** | none stated — **429 to any Ruby client**; reached via the bridge, self-capped 6/min, 200/day | deep | ✅ 1m (7d) / 5m (60d) | ⭐ `.MX`, `^MXX`, div/split | ⚠️ unofficial |
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
2. **Multi-key rotation is prohibited** by four providers. *(Acted on: `ApiKeyPool` and
   `KeyRotation` were retired — one key per provider, [ADR-015](../architecture/adr/0015-one-api-key-per-provider.md).)* Rotating several keys of the *same* provider
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
**All eighteen are resolved** (verified against the code 2026-08-27); each row carries what closed
it. Two — 11 and 16 — turned out to be **wrong**, and are marked ⚠️ and corrected in place rather
than deleted. Three files cited in the Location column **no longer exist**:
`yahoo_finance_gateway.rb` (replaced by `yfinance_gateway.rb` behind the bridge,
[ADR-017](../architecture/adr/0017-python-bridge-for-yahoo-finance.md)), `polygon_gateway.rb`
(the provider was retired) and `stock_fear_greed_gateway.rb` (CNN's index is a proprietary
composite with no substitute, so the block was dropped rather than resourced). Their line numbers
are as of the audit and resolve only in git history.

| # | Finding | Location |
|---|---|---|
| ✅ 1 | Wrong FIX series — uses `SF43718` while the adjacent comment states the goal is what a broker settles against. **Closed by [#318](https://github.com/rodacato/stockerly/issues/318).** | `banxico_gateway.rb:13-15` |
| ✅ 2 | FIX absent before ~12:00 CDMX returns `:not_found` — indistinguishable from an outage. **Closed:** it answers `:not_yet_published`. | `banxico_gateway.rb` |
| ✅ 3 | **No `RateLimiter`** — the only gateway without one, against a provider that blocks the token for a full calendar day and serves both FX and CETES. **Closed:** it has one. | `banxico_gateway.rb` |
| ✅ 4 | `fetch_all_terms` makes 4 calls for one CETES curve; Banxico allows 20 series per request. **Closed by [#320](https://github.com/rodacato/stockerly/issues/320)** — one request, rows matched by `idSerie` because Banxico answers in its own order, not the one asked for. | `banxico_gateway.rb` |
| ✅ 5 | `/v7/quote` 401 makes `fetch_batch_quotes` fall back to **one chart call per symbol** — a ~20× amplifier aimed at the endpoint that rate-limits. **Closed with the gateway:** it was deleted, and DataBursatil took the BMV batch. | ~~`yahoo_finance_gateway.rb`~~ (deleted) |
| ✅ 6 | `/v10/quoteSummary` returns `Invalid Crumb`, so `fetch_earnings` — the only BMV earnings source — returns nothing. **Closed:** BMV earnings go through the bridge, which reaches what `quoteSummary` could not. | ~~`yahoo_finance_gateway.rb`~~ (deleted) |
| ✅ 7 | `fetch_chart` hardcodes `range=1d, interval=1d` and returns only `meta`, not the series; `bars.uniq! { |b| b[:date] }` would collapse any intraday series. **Closed with the gateway.** ⚠️ `CoingeckoGateway` still carries the same `uniq!` — harmless while it only requests daily data, worth remembering before any intraday request lands there. | ~~`yahoo_finance_gateway.rb`~~ (deleted) |
| ✅ 8 | `/stock/candle` is premium — 403 on free keys — and is tagged `:gateway_error`, so `CircuitBreaker` retries a permanent denial forever. **Closed:** the 403 maps to `:no_entitlement`, the breaker opens for an hour instead of retrying every minute, and `:historical` was removed from Finnhub's registration entirely. | `finnhub_gateway.rb` |
| ✅ 9 | `fetch_earnings` calls the retired `/vX/reference/tickers/…/earnings`. **Closed:** Polygon is retired — gateway, registrations, directory entry, seeded stamps and its `Integration` row. | ~~`polygon_gateway.rb`~~ (deleted) |
| ✅ 10 | `BASE_URL` hardcoded to a host announced for retirement. **Closed with the gateway.** | ~~`polygon_gateway.rb`~~ (deleted) |
| ⚠️ 11 | **This row was wrong, and measuring is what showed it.** CoinGecko does not *quote* MXN, it computes it: probed 2026-08-26, the implied USD/MXN was identical across coins (16.9454 BTC, 16.9456 ETH) and sat **0.11% off Banxico's FIX** of 16.9647. Asking for MXN moves the FX hop inside CoinGecko where it cannot be audited, and `asset_price_histories` has no currency column, so the switch would silently relabel every stored crypto row. **Fixed the part that was real:** the literals are one named `QUOTE_CURRENCY` constant carrying the measurement as its reason ([#320](https://github.com/rodacato/stockerly/issues/320)). | `coingecko_gateway.rb:18` |
| ✅ 12 | Unsourced `# Rate limit: ~50 req/day` throttling a source that is not throttled. **Closed:** the comment is gone. | `crypto_fear_greed_gateway.rb` |
| ✅ 13 | Maps only 429, so the 418 block surfaces as a generic error. **Closed by retiring the gateway** — CNN's index is a proprietary composite, so "find another provider" was a false option. It surfaced a second defect fixed with it: `FearGreedReading#stale?` existed and nothing called it, so a stale value rendered as today's; the readers now go through a `fresh` scope. | ~~`stock_fear_greed_gateway.rb`~~ (deleted) |
| ✅ 14 | `data_source` is computed per fetch and **discarded on persist** — `asset_price_histories` and `market_index_histories` have no `source` column. **Closed:** `source`, `interval`, `status`, `as_of` and `fetched_at` exist on both tables and the chain records the winner. | `gateway_chain.rb` |
| ✅ 15 | Registry is decorative on the main path: `for_capability` has two call sites; prices route through a hardcoded `case`. **Closed by [#319](https://github.com/rodacato/stockerly/issues/319):** the registry lacked the dimension that decides routing, not a method — sources now declare `markets` and `asset_types`, and `MarketData::Domain::SourceCatalogue` is the domain object this row asked for. | `sync_single_asset_job.rb` |
| ⚠️ 16 | **This row was wrong: they are not one capability.** `FxRatesGateway#refresh_rates(base:, targets:)` and `BanxicoGateway#fetch_fx_fixes(from:, to:)` have different signatures and are **not substitutable in a chain** — unifying the name would have built a fallback that cannot fall back. **Fixed by distinguishing them:** `:fx_current` (many pairs, now) and `:fx_history` (the FIX series over a range). | `config/initializers/data_sources.rb` |
| ✅ 17 | The quota budget counts **successful log lines, not API calls**: a statements sync spends 3 and logs 1; failures consume quota and are filtered out. **Closed:** `FundamentalsBudget` reads the per-call counter `RateLimiter` maintains, and the limit comes from the same row the screen shows. | `fundamentals_budget.rb`, `sync_statements_job.rb` |
| ✅ 18 | `DAILY_BUDGET = 25` duplicated as a literal instead of reading `FundamentalsBudget::DAILY_LIMIT`. **Closed.** | `sync_all_statements_job.rb` |

**The pattern under all of it:** every one of these surfaced as the same generic `:gateway_error`.
Nothing distinguished *no entitlement* from *rate limited* from *endpoint retired* from *before
publication time* from *blocked by IP reputation*. *S2 Adriana: that is the finding — a chain that
cannot tell a permanent denial from a transient failure will retry the denial and starve the retry.*
**This is what was fixed once rather than eighteen times:** the failure kinds are typed
(`:no_entitlement`, `:not_yet_published`, `:not_found`), and `CircuitBreaker` opens on a permanent
denial instead of retrying it forever.

---

## 5. Role assignment

Rewritten 2026-08-26 from live probes rather than documentation, then **re-checked against the
registered wiring on 2026-08-27** — the ⚠️ marks are the audit's own "changed against the first
draft"; the **⛔ marks are rows this table got wrong or that the wiring has since moved**, and each
says where it went. Read `config/initializers/data_sources.rb` for what is actually registered;
this table is the reasoning behind it, not its source of truth.

| Capability | Primary | Fallback | |
|---|---|---|---|
| BMV quotes + EOD + intraday | **DataBursatil** | the yfinance bridge (prices, EOD) | ✅ verified |
| BMV fundamentals + statements | DataBursatil `/v2/financieros` | — | ⚠️ still blocked on the emisora key |
| **IPC / MX indices** | **the yfinance bridge** | — | ⚠️ **changed** — DataBursatil's index feed is frozen at 2026-06-26 |
| **BMV dividends + splits** | **the yfinance bridge** | — | ⛔ **moved** — the same Yahoo data, now behind the bridge and routed by market ([#312](https://github.com/rodacato/stockerly/issues/312)) |
| MX rates (TIIE) | DataBursatil | — | not probed |
| MX news | DataBursatil (`get_cables`) | — | not probed |
| **US prices — confirmed EOD** | **Alpaca** (`feed=sip`) | the yfinance bridge | ⛔ **Finnhub is no longer the fallback** — `/stock/candle` is premium, so `:historical` was removed from its registration rather than left to 403 |
| **US quote — current** | **Finnhub** | — | ⚠️ **changed** — Alpaca 403s on every recent surface |
| **US indices (SPX/DJI)** | **the yfinance bridge** | — | ⚠️ **changed** — no free source anywhere else |
| US intraday / provisional | — | — | ⛔ **nothing is registered for `:intraday` outside DataBursatil/BMV**; the bridge does not declare it |
| US fundamentals + statements | Alpha Vantage | FMP *(`maintainer_only`; `/api/v3` is gated to pre-2025-08-31 accounts)* | pending the OSS grant |
| **Dividends + splits (US)** | **Alpaca** `/v1/corporate-actions` | — | ⛔ **FMP is no longer the fallback** — it is scoped to `:fundamentals` and labelled `maintainer_only`, because an unlabelled fallback only the maintainer can reach is the defect ([#312](https://github.com/rodacato/stockerly/issues/312)) |
| Earnings | **Finnhub** (US) · the bridge (BMV, by an explicit route in `SyncEarnings`, not a chain) | — | ⚠️ Alpaca has none; this is D-5's over-commitment |
| News | Alpaca `/v1beta1/news` | Finnhub | ✅ verified free on Basic |
| Crypto | CoinGecko, **quoted in USD on purpose** | — | ⛔ **reversed** — CoinGecko computes MXN from an undisclosed rate 0.11% off the FIX; requesting it would hide the FX hop, not remove it ([#320](https://github.com/rodacato/stockerly/issues/320)) |
| FX — valuation basis | **Banxico FIX `SF60653`** (`:fx_history`) | — | ✅ landed ([#318](https://github.com/rodacato/stockerly/issues/318)) |
| FX — current rates | `FxRatesGateway` (`:fx_current`) | — | a different capability, not a fallback for the above |
| CETES | Banxico | ~~DataBursatil `guber`~~ | ❌ **closed 2026-09-05** — no date serves it, the docs' own example date included, while `hechos` served the same days |

**The correction that matters: Yahoo carries more weight after this research, not less.** The first
draft concluded that DataBursatil ends BMV's sole dependency on an unsanctioned endpoint. It ends it
for **prices** — quotes, EOD and now sanctioned intraday — and **not** for indices or dividends, two
of the three capabilities that were credited to it. Alpaca has no indices either, and Massive's are a
paid product. So Yahoo is now the only source of indices for **both** markets and the only source of
BMV corporate actions.

That promoted the question of whether Yahoo answers **from the production host** back to the top of
the list — and **that question is now answered**: it does not, from anywhere a Ruby client calls it.
The block is on the TLS fingerprint, and the answer was
[ADR-017](../architecture/adr/0017-python-bridge-for-yahoo-finance.md) — a Python subprocess whose
client presents a browser handshake, quarantined to exactly the three capabilities named above.

---

## 6. Verified, and what is still open

**Settled by live probes on 2026-08-26** (`redesign/probes/probe.rb`, output under `out/`):
DataBursatil's base URL, auth shape, error format, working endpoints and **credit model** (1 KiB,
rounded up — a 9,791-byte response cost 10); Alpaca's feed default, its hard 403 inside 15 minutes,
its absent indices and earnings, and its free news and corporate actions.

**Answered since, and struck from the list:** *whether Yahoo's endpoints work from the production
host.* They do not — nor from a residential connection, nor from the devcontainer, and the crumb
bootstrap 429s on the crumb endpoint itself. The block is the TLS fingerprint, and
[ADR-017](../architecture/adr/0017-python-bridge-for-yahoo-finance.md) is the answer that closed it.

**Resolved by decision, not by reading (2026-08-27).** Two rows left this list without anyone
answering the question they asked — the question stopped mattering:

- **DataBursatil's terms of service.** This was load-bearing only because five providers in this
  stack forbid redistribution. **Stockerly never redistributes a provider key.** Onboarding links
  each provider's sign-up so every self-hoster registers their own credential, so the
  redistribution clause has nothing in this product to attach to. What is still unread is
  narrower — whatever the terms say about storing or displaying the data a self-hoster fetched
  with their own key — and at one instance per person that does not earn a ticket.
- **Whether Alpha Vantage's open-source grant applies.** Deferred on purpose: *"no creo que sea
  tan viable, pero es long term, el proyecto está aún muy joven."* **25 calls a day stays the
  working assumption**, so `FundamentalsBudget`, the tier ladder and the quota the Integraciones
  screen renders all stand as built. Revisit if the project ever outgrows that ceiling — not
  before.

**Answered 2026-09-05, both by reading the docs the audit could not open** (they 403 a bare client
and return 200 to a browser `User-Agent` — worth knowing before the next question is deferred as
unanswerable):

- **`/v2/emisoras` filtering** — [#379](https://github.com/rodacato/stockerly/issues/379). ✅ **The
  filter exists**: `letra` (a letter or a whole ticker) and `mercado` (`local` / `global`). A
  filtered call is ~350× cheaper than the catalogue and carries `rango_financieros`, so
  `/v2/financieros` was never blocked on the 2,181-credit fetch. See §the credit model above.
- **Q-8, `descargas` with `archivo=guber`** — [#380](https://github.com/rodacato/stockerly/issues/380).
  ✅ **Closed as unavailable.** The archive name is valid and accepted; no date holds a file, and
  `hechos` served every date `guber` refused. See §the three documented capabilities above.

Still open, and still unticketed — verifications the audit owed and never paid:

- Alpha Vantage's BMV coverage via `.MEX` — reported, not probed.
- DataBursatil's `tasas`, `divisas`, `cables` and `noticias` endpoints — not probed.
- Whether any **sanctioned alternative to Yahoo** exists for MX indices and corporate actions. The
  bridge made Yahoo reachable; it did not make it sanctioned, and ADR-017 quarantines it precisely
  because this question is still open.
