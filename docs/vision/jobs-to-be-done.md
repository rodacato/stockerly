# Jobs to be Done — Stockerly

> The 7 JTBDs that justify Stockerly's existence. Six were written 2026-05-14; **reviewed against the
> 2026-08-20 pivot** ([ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)),
> which changed the audience and not these six — JTBD #5 (fast capture) and #6 (readable
> indicators) were promoted to central, since data-entry friction and indicator illiteracy are two
> of the three failures that ended the closed beta. Statuses last verified against the code
> **2026-08-27**.
> Each JTBD here is the **expansion** of the lines that appear in [`audience.md`](./audience.md).
> A new feature in the backlog must map to one of these (or propose a new JTBD via an edit to this file).
> **JTBD #7 was added 2026-08-29** by the per-symbol news block (#427), which is the first feature since
> the pivot that mapped to none of the six.

---

## Structure of each JTBD

```
**Statement** — the canonical phrase "When X, I want Y, so that Z"
**Required data** — what must exist in DB/gateways
**App surface** — where the user sees it
**Triggers** — what proactively surfaces it (if applicable)
**Usage metric** — how we'll know the JTBD is fulfilled
**Blocked by** — current debt that prevents fulfillment
**Current status** — how close it is today
```

---

## JTBD #1 — Consolidated patrimony in MXN

**Statement:** *When I review my portfolio over the weekend, I want to see my total patrimony consolidated in MXN, so I can know whether I'm up or down since last time.*

**Required data:**
- Current positions (`positions` table)
- Current prices (gateways: Alpaca and Finnhub for US equities, DataBursatil for BMV, CoinGecko
  for crypto, Banxico for CETES)
- Current USD→MXN FX rate (`FxRatesGateway`, capability `:fx_current`)
- USD→MXN FX rate at the moment of each purchase — **exists**: captured as
  `fx_rate_at_execution` from the Banxico FIX settlement series (`SF60653`, ADR-009)
- Historical snapshots (`portfolio_snapshots`) for chronological comparison

**App surface:**
- Panorama (`/dashboard`) — the patrimonio strip, in MXN
- Consolidado (`/portfolio`) — the total, its history, and the comparisons

**Triggers:** none. It's data always visible when opening the app.

**Usage metric:** Adrian opens the dashboard ≥1 time per week on weekends. If it drops below 1/month, the JTBD is not being fulfilled.

**Blocked by:** nothing. The P0 is fixed — `ExecuteTrade` takes the currency from the trade or the asset and captures `fx_rate_at_execution` against MXN through `Trading::Domain::ExecutionRate`, and `PortfolioSummary#total_invested` derives cost basis at historical FX (ADR-009).

**Current status:** delivered. The Consolidado (`/portfolio`) shows the total in MXN, its history, and how it compares against CETES; the Panorama's strip carries it daily. `day_gain` subtracts capital flows so a late-recorded purchase no longer reads as a gain (D27).

---

## JTBD #2 — Position drawdown from average cost in MXN

**Statement:** *When my position drops X% from average cost (in MXN), I want to know, so I can decide whether to average down or exit.*

**Required data:**
- `position.avg_cost` in the currency of acquisition
- Cost basis at historical FX — **exists**: `PortfolioSummary#total_invested` and
  `Position#avg_cost_in` derive it from `fx_rate_at_execution` (ADR-009)
- Current price (USD for equities, MXN for CETES)
- Current FX rate
- Threshold X (user-configurable; suggested default: -10% for warning, -15% for alert)

**App surface:**
- Portfolio page — badge on each position that crossed the threshold
- Dashboard — "Notable observations" section if there are positions below threshold
- Alerts — in-app notification when a position first crosses the threshold (mandatory cooldown)

**Triggers:** EOD job reviews all positions, fires alert when one crosses the threshold downward (no spam if already below).

**Usage metric:** Adrian opens the alert/badge within 24h of generation (proxy: click event). If he consistently ignores them, the JTBD isn't working.

**Blocked by:** nothing. The same P0 fix that unblocked JTBD #1 gives this one its cost basis at historical FX.

**Current status:** the currency fix landed, so the percentage is honest. The asset detail's Mi posición splits the drawdown into what the asset did and what the peso did. An AlertRule variant for "X% from MXN cost basis" is still missing.

---

## JTBD #3 — CETE about to mature

**Statement:** *When a CETE is about to mature, I want to know with 7 days of lead time, so I can decide whether to reinvest.*

**Required data:**
- `asset.maturity_date` for asset_type CETE
- Active positions in CETE-type assets
- Calendar (Banxico business days for accuracy)

**App surface:**
- Dashboard sidebar — "Upcoming events" listing CETES near maturity
- Asset detail of each CETE — visible countdown
- Alerts — notification at 7d, 3d, 1d before

**Triggers:** Daily cron job; check positions against maturity_date.

**Usage metric:** Adrian reinvests (or explicitly chooses not to) within 48h after maturity. Proxy: new trade or explicit alert dismissal.

**Blocked by:** nothing structural blocks. CETES have been modeled since Phase 13.1 with the Mexican `YieldCalculator`.

**Current status:** working. `NotifyMaturitiesJob` runs daily and the Panorama's Radar keeps a fixed-income position visible when it matures within 30 days, even on a day it did not move.

---

## JTBD #4 — Earnings on held assets

**Statement:** *When an earnings event is coming for something I hold, I want to know 2 days ahead, so I don't find out after the fact.*

**Required data:**
- Earnings calendar — Finnhub for US, the yfinance bridge for BMV emisoras
  ([ADR-017](../architecture/adr/0017-python-bridge-for-yahoo-finance.md))
- User's current holdings (active positions)
- Match between holding tickers and tickers in earnings calendar

**App surface:**
- Dashboard "Upcoming events" — earnings on holdings with BMO/AMC + EPS estimate
- Earnings page filtered by my holdings
- Notification — 2d, 1d before (with details)

**Triggers:** `NotifyEarningsJob` daily, 7am. Matches holdings vs upcoming earnings, deduplicated with `last_triggered_at` per event.

**Usage metric:** Adrian opens the asset detail of the ticker with upcoming earnings before the event. Proxy: page view of the asset between alert and earnings.

**Blocked by:** nothing. Implemented since Phase 14.4 (`Earnings::NotifyApproaching`).

**Current status:** working. Notification copy goes through `Alerts::Domain::TriggerNotice` — fact in the title, provenance in the body.

---

## JTBD #5 — Fast trade capture

**Statement:** *When I add a new trade, I want to capture it in under 30 seconds, so I don't abandon the recording out of laziness.*

**Required form data:**
- Ticker (with autocomplete against `assets`)
- Shares
- Price (in native currency)
- **Currency (auto-detected from the asset)** ✅
- Date (default: today; max: today; min: ¿1 year back?)
- FX rate at the time of the trade — **built**: the sheet auto-fills the Banxico FIX for the
  date entered
- Optional notes, optional labels

**App surface:**
- Activos — the trade sheet at `/trades/new`, presented as a drawer (D11)

**Friction points (to measure and reduce):**
1. Ticker search — should be <300ms with debounce
2. FX capture — should be automatic, not manual
3. Currency decision — should be auto from the asset
4. Reasonable-price validation — immediate feedback if very different from current price

**Usage metric:** time from "open form" to "submitted". Target: P50 < 30s, P95 < 60s.

**Blocked by:** nothing. The sheet auto-fills the Banxico FIX for the date entered, which made the correctness fix and the data-entry win the same field.

**Current status:** delivered as a drawer at `/trades/new` (D11) — native `<dialog>`, sticky total and save, `visualViewport` handling. `executed_at` is now bounded at today, which this section always specified and nothing enforced. **"Guardar y registrar otro" is still not built.**

---

## JTBD #6 — Position in notable technical zone

**Statement:** *When one of my positions (or a watchlist asset) enters a notable technical zone (oversold/overbought per RSI, Bollinger Bands breakout, moving-average crossover), I want to see it described in context, so I can factor it into my weekly portfolio reflection.*

**Required data:**
- Historical daily prices ≥200 days — **does not exist.** `BackfillPriceHistoryJob::DAYS` fetched
  30 until 2026-08-29; the table accumulates one row a day from there, so no asset has ever had
  the 200 this line claims. Corrected 2026-08-29 — see `design/V2_REMAINING.md` X9
- Per-asset computed indicators (RSI(14), MACD, BB, MA50, MA200, EMA9/21)
- TrendScore 5-factor (already exists)
- User holdings + watchlist

**App surface:**
- Asset detail — "Technical analysis" section with current indicators + descriptive interpretation
- Dashboard — "Notable observations" section when ≥1 relevant asset enters a zone
- Market listings — hover/click reveals TrendScore breakdown (exists since Phase 21.1)

**Triggers:**
- Daily EOD job: recompute indicators, detect transitions (asset entered oversold today / crossed MA50 today)
- Generate "observation" when a transition occurs, associated with user's holding/watchlist
- Dedup: one observation per asset/zone/week (cooldown)

**Required language (ADR-001):**
- ✅ *"AAPL appears oversold per RSI(14) = 28"*
- ✅ *"NVDA crossed below its MA200"*
- ❌ *"Consider buying AAPL"*

**Usage metric:** Adrian opens ≥1 asset detail per week from a surfaced notable observation. If he ignores them, the JTBD isn't working or the observations are too noisy.

**Blocked by:** the data precondition above, for the half of this JTBD that needs long windows.
Dedup and copy are fine — dedup happens at write time (`persist_if_fresh`) and the phrases live in
`MarketHelper::OBSERVATION_PHRASES`. But MACD, MA50 and MA200 all need more closes than the app
has ever held, so the indicators this JTBD lists have never run in production. **This line read
"nothing" from 2026-05-14 to 2026-08-29**, which is why the gap survived three audits: the
requirement was written down, marked satisfied, and never measured.

**Current status:** delivered on three surfaces — the Panorama's "Movimientos de interés", the asset detail's verdict card, and its "Observaciones recientes". The verdict card reads a state out loud under [ADR-014](../architecture/adr/0014-state-phrases-from-a-closed-catalogue.md); the observations block stays purely descriptive. Threshold tuning is still untouched.

---

## JTBD #7 — What was published about something I follow

**Statement:** *When I open a symbol I hold or watch, I want to see what was published about it recently, so a move I do not understand has somewhere to be explained — and so I find out about it here rather than by accident.*

**Why this is not JTBD #4.** Both answer *what happened to my asset*, and folding this into #4 was
the first reading. It does not hold: #4 is a **scheduled** event on a **held** asset, announced
**two days ahead** by a notification. This is **unscheduled**, reaches **watched** assets too, and
is read **after the fact** on a screen the reader already chose to open. #4's usage metric — opening
the detail *before* the event — cannot measure it. Two mechanisms, two metrics, two JTBDs.

**Required data:**
- `news_articles` rows carrying `related_ticker` — **exists**, and had no reader until 2026-08-29.
  `SyncNewsJob` fills them every 30 minutes ([`recurring.yml`](../../config/recurring.yml)) through
  the `:news` capability (Alpaca, Finnhub)
- `Asset#former_symbols`, so a renamed ticker keeps the articles filed under the old one
- `published_at` and `source` per article, both non-null; `url` when the provider sent one

**App surface:**
- Asset detail (`/market/:symbol`) — a capped block under *Observaciones recientes*, bounded to
  `MarketData::Queries::RecentNews::WINDOW_DAYS`. No article means no block

**Triggers:** none, deliberately. This is read where the reader already is. It is **not** a
notification and **not** a listing — D31 deleted `/news` and was right to; a river of headlines is
the bubble Descubrir exists to leave.

**Usage metric:** Adrian clicks through to ≥1 article per fortnight from an asset detail. Below
that, the block is a headline river on a screen built to avoid one, and it is **deleted** — along
with `SyncNewsJob`, which would then be spending provider quota on nothing. That deletion clause is
the point of the metric: this is the JTBD most likely to decay into noise.

**Blocked by:** nothing.

**Current status:** delivered 2026-08-29 (#427). Headlines render as their source wrote them and
are attributed; [ADR-001](../architecture/adr/0001-descriptive-not-prescriptive-language.md) governs
our copy, and a third party's headline is quoted material. No summarisation and no sentiment scoring
over headline text — that would make it our sentence.

---

## How a new JTBD gets added

1. Documented personal trigger: *"On [date] I encountered [specific situation], and [information/action] wasn't available in Stockerly"*.
2. Statement in canonical format: *"When X, I want Y, so that Z"*.
3. Data, surface, triggers, metric, blockers — fill in the 6 sections.
4. Edit `audience.md` and vision's `README.md` to reflect the new JTBD count.
5. Commit with message *"docs(vision): add JTBD #N — [brief statement]"*.

## How a JTBD gets retired

If after 90 days of being implemented:
- The usage metric isn't met (Adrian doesn't use it with expected frequency)
- Or Adrian explicitly admits it doesn't serve him

→ retro flags it for retirement. Backlog issue: *"Retire JTBD #N: reason"*. The associated features are evaluated case by case (some may stay as observable infra, others get de-implemented).
