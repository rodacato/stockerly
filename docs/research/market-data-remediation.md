# Market data — remediation queue

> The eighteen findings from [market-data-providers-2026-08.md](market-data-providers-2026-08.md) §4,
> triaged by whether they can be fixed **now** or will be **reshaped by the engine work**
> ([ADR-016](../architecture/adr/0016-canonical-market-data-observations.md)).
>
> **This document dissolves into GitHub Issues.** It exists so nothing is lost between the audit and
> the board; delete a row once its issue is open, and delete the file once all of them are.
>
> **Done 2026-08-26:** multi-key rotation retired per
> [ADR-015](../architecture/adr/0015-one-api-key-per-provider.md), and **all of group A with it**.
> Two of those five turned out not to be what this document said they were — recorded below rather
> than quietly corrected, because the mis-triage is the useful part.

---

## A — Done (2026-08-26)

Nothing in the engine work changed these, and they are landed.

| # | Fix | Where | Note |
|---|---|---|---|
| ✅ A1 | **Add a `RateLimiter` to Banxico** | `banxico_gateway.rb` | The only gateway without one, against a provider that blocks the token for a **full calendar day** — and that token serves FX *and* CETES. Purely additive. Highest value-per-line in the list. |
| ✅ A2 | **Delete the unsourced rate-limit comment** | `crypto_fear_greed_gateway.rb:4` | `# Rate limit: ~50 req/day` has no source and throttles a source that returns 3,125 daily points free. One line. |
| ✅ A3 | **Read `FundamentalsBudget::DAILY_LIMIT` instead of the literal** | `sync_all_statements_job.rb:8` | One number, two sources of truth. One line. |
| ⚠️ A4 | **This document was wrong: they are not one capability.** The fix was to *distinguish* them, not unify them | `config/initializers/data_sources.rb` | `FxRatesGateway#refresh_rates(base:, targets:)` and `BanxicoGateway#fetch_fx_fixes(from:, to:)` have different signatures and are **not substitutable in a chain** — merging their capability name would have built a fallback that cannot fall back, which is worse than the ambiguity it removed. Renamed to say what each is: **`:fx_current`** (many pairs, now) and **`:fx_history`** (the FIX series over a range), matching their jobs. |
| ✅ A5 | **Retire the CNN Fear & Greed gateway** | `stock_fear_greed_gateway.rb` | Gateway, registration, seeded integration, provider-directory entry and the job's stocks half are gone. Both readers degrade cleanly — the carousel omits the card, the asset detail omits the sentiment. 🐞 **It exposed a second defect, fixed with it:** `FearGreedReading#stale?` existed and **nothing called it**, so the last stored value rendered as if it were today's; `latest_crypto`/`latest_stocks` now go through a `fresh` scope, which protects crypto against the same failure. **The design half closed with it — [D38](../../design/DECISIONS.md): drop the block.** "Find another provider" was a false option: CNN's index is a proprietary composite, so any substitute is a different indicator wearing its label. The artboards lost the card and the line; `VIX` stays seeded for the day equity sentiment earns its own 4-filter card. |

## B — Fix now, but they are not as small as they look

Each is a short diff with a consequence that needs deciding first. Do not batch these with group A.

| # | Fix | Why it is not trivial |
|---|---|---|
| B1 | **Banxico FIX series `SF43718` → `SF60653`** | Looks like one constant, and closes the multi-currency P0 residual — but existing `fx_rate_histories` rows are keyed to the **determination** date and new ones would be keyed to the **settlement** date. Two conventions in one table is worse than the current state. **Needs a backfill decision before the constant changes.** |
| B2 | **Kill the Yahoo batch-quote amplifier** | `/v7/quote` returns 401 permanently, so `fetch_batch_quotes` falls back to **one chart call per symbol** — ~34 calls where there should be 1, aimed at the endpoint that rate-limits, from an IP class that already 429s. This is live damage. But removing the fallback means the batch path returns a failure instead of silently degrading, and **something has to handle that** — decide the replacement before deleting the fallback. |
| B3 | **CoinGecko: request MXN natively** | `vs_currency=usd` is hardcoded in three places and `data["usd"]` is parsed in a fourth. CoinGecko quotes MXN directly, so we are converting a number the source could have given us — but this touches money parsing, so it needs its specs first. |
| B4 | **Batch the CETES curve into one request** | `fetch_all_terms` makes 4 calls where Banxico allows **20 series per request**. A clean win against the provider most at risk of a day-long block — but it is a real refactor of the parsing, not a parameter change. |

## C — Defer: the engine will reshape these

Fixing them now means fixing them twice. Each is listed with what it is waiting on.

| # | Finding | Waiting on |
|---|---|---|
| C1 | `data_source` computed by `GatewayChain` and **discarded on persist** (`gateway_chain.rb:33`) | ADR-016's `source` column |
| C2 | Registry decorative on the main path — `for_capability` has 2 call sites while prices route through a hardcoded `case` (`sync_single_asset_job.rb:63`) | `Source` as a domain object |
| C3 | Banxico returns `:not_found` before ~12:00 CDMX — a normal daily condition indistinguishable from an outage (`banxico_gateway.rb:135`) | typed failures |
| C4 | Finnhub `/stock/candle` is premium; the 403 is tagged `:gateway_error`, so `CircuitBreaker` retries a permanent denial forever | typed failures |
| C5 | The quota budget counts **successful log lines, not API calls** — three ways (`fundamentals_budget.rb`, `sync_statements_job.rb:31,33`) | provider-defined quota units; also gated on the Alpha Vantage open-source grant, which may remove the budget entirely |
| C6 | Yahoo `/v10/quoteSummary` returns `Invalid Crumb`, killing `fetch_earnings` — the only BMV earnings source (`yahoo_finance_gateway.rb:118`) | the DataBursatil gateway, which supersedes it for BMV |
| C7 | `fetch_chart` hardcodes `range`/`interval`, returns only `meta`, and `parse_historical`'s `uniq!` would collapse an intraday series (`yahoo_finance_gateway.rb`, `:355`) | the provisional-series decision, itself deferred |
| C8 | Polygon `fetch_earnings` calls a retired endpoint (`:83`); `BASE_URL` points at a host announced for phase-out (`:8`) | **Unblocked 2026-08-26 — but it is two migrations, not one.** Polygon serves four roles and Alpaca replaces exactly one: `fetch_grouped_daily` and `fetch_historical` → **Alpaca** (`/v2/stocks/bars`, `feed=sip`, paginated); `fetch_price` → **Finnhub**, because Alpaca 403s on every surface inside 15 minutes; `fetch_earnings` → **Finnhub**; `fetch_index_quotes` → **nobody**, so it stays on Yahoo. |
| C9 | FMP `/api/v3/` is legacy-gated to pre-2025-08-31 accounts — **works on the maintainer's key, 403s for every new self-hoster** | **Unblocked 2026-08-26.** Alpaca's `/v1/corporate-actions` is free on Basic and returns dividends and splits with `ex_date`, `payable_date`, `record_date` and `rate` — more fields than FMP. FMP drops to a fallback, and Integraciones has to **say** it only works on pre-existing keys; an unlabelled fallback that fails for everyone but the maintainer is the defect, not the dependency. |

---

## D — Opened by the 2026-08-26 probes

Two capabilities the audit believed were covered are not. Both leave Yahoo as the sole source.

| # | Finding | Why it is open |
|---|---|---|
| D1 | **MX and US indices have no sanctioned source.** DataBursatil's `/v2/indices` answers but is **frozen at 2026-06-26** — byte-identical across calls, while its own `/v2/cotizaciones` serves same-day data. Alpaca has no indices (`SPX` returns `{"bars":{}}` with HTTP 200). Massive's are a paid product. | `SyncMarketIndicesJob` and `SyncIndexHistoryJob` run on Yahoo with a Polygon fallback that was already paid-only, so **Yahoo is the only index source for both markets**. |
| D2 | **BMV dividends have no sanctioned source.** `/v1/dividendos` and `/v2/dividendos` both **404** although the docs table lists the former. | Back to Yahoo's `events=div,split`, the unofficial endpoint the DataBursatil work was meant to retire. The `emisoras` catalogue carries a per-issuer `dividendos` field — a lead, not a route. |

Neither is a regression: nothing worked before and nothing works now. What changed is that the plan
assumed DataBursatil closed both, and it does not — which is why *"does Yahoo answer from the
production host?"* moved from a nice-to-have back to the top of the list.

## The pattern worth fixing once

Every finding above surfaces as the same generic `:gateway_error`. Nothing distinguishes *no
entitlement* from *rate limited* from *endpoint retired* from *before publication time* from *blocked
by IP reputation*. That is why group C is deferred rather than picked off: **typed failures on a
`Source` object fix the diagnosis for all of them at once**, and patching each error string
individually would be the work thrown away.

## Not findings — verifications still owed

| | |
|---|---|
| ✅ Read DataBursatil's docs *(endpoints done 2026-08-26; **terms still unread**)* | five providers forbid redistribution and this one is still unknown |
| Read the `/v2/emisoras` docs section for a filter parameter | unfiltered it costs ~2,181 credits (~1% of the monthly quota) and it is what blocks `/v2/financieros` |
| 🔺 `curl` Yahoo's chart endpoint from andys-room | **Priority raised 2026-08-26.** A datacenter IP returned 429 on the first request, and group D leaves Yahoo as the sole source of indices for both markets and of BMV dividends. |
| Apply for Alpha Vantage's open-source grant | unlimited vs 25/day — it may delete C5 and the budget model with it |
| Probe `descargas` with `archivo=guber` on a date that exists | probed on three dates 2026-08-26; the archive name was never rejected, only the dates (*"La fecha ingresada no esta disponible"*), so Q-8 is unresolved rather than answered |
