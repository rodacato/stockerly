# Code changes — landing the redesign in code

> The WORK ORDER for landing design-side decisions in code. A `Dn` entry in
> [DECISIONS.md](DECISIONS.md) records the finding + decision; this doc tracks its **execution**.
> Because this is a redesign, the kit leads the code — each section flips the kit from "ahead of
> code" to "1:1 mirror" once it ships.

**Rule: consolidation/adoption decisions cite MEASURED usage, not impressions.** Lead each section
with grep counts.

## 0. Pre-work before the first slice (D21, D22)

Four small changes that make every later slice cheaper, and one that must land before any view
depends on the current structure. None of them is a refactor for its own sake.

| # | What | Why it goes first |
|---|---|---|
| 0.1 | **Untangle `data-theme`** (ADR-012): it names the palette (`lumen`), the `dark` class carries the mode. Retire the `[data-theme="dark"]` selector. | Zero redesigned views exist yet, so the cost is one CSS file. After the first slice it is a sweep. |
| 0.2 | **Expose the fonts as `@theme` tokens** (`--font-display / --font-sans / --font-mono`). The families already load from Google Fonts and already exist as CSS vars — they are just not Tailwind utilities. | Three lines; unblocks the typography that carries the whole visual change (D1: colour is a no-op, type and shape are the redesign). |
| 0.3 | **Set up I18n + `i18n-tasks`** (ADR-011): `config/locales/es-MX.yml`, lazy-key convention, `i18n-tasks health` in CI. | Every slice writes copy. Adding the layer after the first slice means rewriting that slice's strings. |
| 0.4 | **`lightweight-charts` via importmap** + a smoke Stimulus controller (D2). | Pure de-risking: two of the heaviest screens depend on it. Better to learn it misbehaves self-hosted now than mid-slice. |
| 0.5 | **Component inventory**: cross the existing `app/views/components/` partials against the kit's 13 components — 1:1, net-new, or dead. → [COMPONENT_INVENTORY.md](COMPONENT_INVENTORY.md) | This *is* the work order for the translation. It found 8 of the 19 partials dead or broken, so the crossing is 11 against 13. |

**Already done, verified rather than assumed:** the PWA is wired (manifest with maskable icons,
`display: standalone`, service worker registered, `theme-color` already `#5B6CFF`) — only its
pre-pivot name and description need rewriting. The pivot's subtraction also landed: `email_event`,
`user_activity`, `invite_code` and `remember_token` are gone; only `api_key_pool` remains, and D18
keeps it deliberately.

**Not pre-work:** consolidating the layouts (it falls out of the shell slice) and any broader
refactor — the suite is green at 94% coverage and moving code no screen has asked for is risk
without payoff.

## 0b. Verifications owed — none of these are code, all of them are real

Everything below shipped and passed its gates. These are the checks a machine in
this container could not perform, listed so they are not mistaken for done.

| What | Why it is still open | How to close it |
|---|---|---|
| **The typography, visually** | Until §0.2 no font resolved: `font-mono` fell back to ui-monospace across 175 sites and Inter never applied to `<body>`. The fix changes how the whole app looks and **no human has seen it**. | `bin/dev`, look at a data-heavy screen in both themes |
| **The trade sheet on a real phone** | D11 exists because the iOS keyboard covers a bottom-anchored sheet. That does not reproduce in headless Chrome on Linux, so the five specs prove the mechanism and not the reason. | Open `/trades/new` on an iPhone, focus a numeric field, confirm Total + Guardar stay reachable. The `Con teclado` artboard is the acceptance target |
| **`/assets` behind Cloudflare** | Propshaft owns that prefix. If the tunnel caches `/assets/*` as static, an authenticated page could be cached at the edge. Verified in test, never in production. | `curl -sI https://stockerly.notdefined.dev/assets \| grep -i cf-cache-status` — a `HIT` on an authenticated page means excluding the path or moving the route |

## 1. New `@theme` token values (D1)

**Status:** pending — waiting on the approved identity pass.

- Swap the Lumen values in `app/assets/tailwind/application.css` `@theme { }` for the redesign's,
  keeping the token **names** (contract) so views resolve unchanged. Add `--font-display /
  --font-sans / --font-mono`.
- Measure before landing: `grep -rc "bg-bg-\|text-fg-\|border-border-\|bg-positive\|bg-negative" app/views | ...`
  — confirm the contract names in use, so a value swap is safe and a rename is not needed.

## 2. Chart component (D2)

**Status:** pending — design first.

- Add `lightweight-charts` via importmap; a `PriceChart` Stimulus controller fed by our existing
  close series (the same data behind RSI/Bollinger/SMA). No TradingView iframe.

## 3. Panorama (slice 3) — DONE

**Status:** shipped. `/dashboard` renders the cockpit; the old surface is deleted, not left beside it.

- ✅ **`Trading::UseCases::AssemblePanorama`** replaces `AssembleDashboard`. Four blocks:
  `PatrimonioStrip`, the sentiment carousel, "Movimientos de interés", the Radar.
- ✅ **The 🐞 is dead.** `/dashboard` raised `Missing FX rate USD->MXN` with one USD position,
  `preferred_currency: "MXN"` and no `fx_rates` row — and it raised **in the template**
  (`show.html.erb:44`), because the old use case built `PortfolioSummary` without ever valuing it.
  The new one calls `total_value` and `day_gain` inside the use case and rescues there, exactly as
  `LoadAssets#consolidated_summary` does. The strip degrades to "Sin consolidar"; the Radar still
  renders, because only the consolidation was ever impossible.
- ✅ **`compra` / `vende` chips ship** — under
  [ADR-013](../docs/architecture/adr/0013-action-labels-on-persisted-observations.md), which amends
  ADR-001 (D24). The verb comes from `MarketData::Domain::ObservationAction`, a lookup over a
  persisted `TechnicalObservation` and the only place the mapping exists. A reading that is not
  from today is dated on the row. Cross-context read goes through the new
  `MarketData::Queries::NotableObservations`, so Trading no longer touches `TechnicalObservation`
  directly the way the old controller did with an apology in a comment.
- ✅ **"vs ayer" on all three sentiment cards.** F&G deltas come off the history the query already
  returned (`RefreshFearGreedJob` runs daily, and the comparison skips today's rows so a re-run
  cannot report "vs this morning"); the watchlist delta needed
  `MarketSentiment.delta_for_user`, reading yesterday's trend scores.
- ✅ **The sparkline is a line and carries real data.** It was a bar chart, and `_asset_row` called
  it **without `heights`** — so Cartera drew an invented shape while `_watchlist_table` and
  `_listings_table` passed real closes. Both fixed; `_watch_row` gained the sparkline the design
  draws.
- ✅ **The 2.0 shell has an `h1` again.** §6b planned for a screen to hand its title to the bar and
  the bar to become the `h1`; the second half never happened, so **no 2.0 screen had one** — Activos
  and Rastreados included. The desktop bar's title is now an `h1`, and the layout emits an `sr-only`
  one below `lg`, where the mobile TopBar carries no title at all.
- ✅ **Deleted with the old screen:** seven partials, three lazy sub-routes
  (`news_feed`, `trending`, `notable_observations`) and their views, `AssembleDashboard`, and
  ~50 examples across nine spec files that asserted the retired surface.
- ⚠ **Not built, deliberately.** The state chip and the confluence dots (same reason as §4 — the
  chip has no taxonomy in code, the semáforo is D3 and gated). The carousel's **dots**: they need JS
  to follow the scroll, and a static row that never moves is a worse lie than the peeking next card.
  The black-swan **market-event banner** — D25: nothing in `app/` or `lib/` computes breadth.
- 🐞 **`lightweight-charts` did not get its debut here, and should not have.** The only chart on this
  screen is a ~60×20px sparkline, five per view; `PriceChartController` is written for a 220px chart
  with grid, axes and a `timeScale`. Five canvases plus five `ResizeObserver`s for a sparkline is
  the wrong tool on the most-opened screen. It debuts in the asset detail, where
  `cockpit-asset-analisis` draws the chart it was written for.
- 📸 **Two defects only a screenshot found**, both invisible to a green suite:
  1. The desktop three-column layout **did not render** on the first capture. Cause: the local
     `app/assets/builds/tailwind.css` predated the new template, so `lg:col-span-4`, `lg:order-*`,
     `snap-x` and `stroke-positive` were simply absent — the sparklines were invisible for the same
     reason. CI builds the CSS; a local cuprite run does not. **Run `bin/rails tailwindcss:build`
     before trusting any local screenshot.**
  2. The sparkline drew a **falling line painted green**. Its shape came from seven daily closes and
     its colour from `change_percent_24h` — two windows that disagree whenever the week and the day
     do. Colour now comes from the same closes that draw the shape.
- ⬜ **Left as drawn, for Adrian to call:** in the Radar's narrow desktop column the inline
  sparkline squeezes the asset name to an ellipsis (`Vanguard S&P 500 · 102 …`). The artboard puts
  the sparkline on its own line beneath the name; `_asset_row` keeps it inline, which reads fine in
  Activos' wide grid and truncates here. Restructuring the row touches slice 2's screen, so it did
  not ride along.
- ⬜ **Orphaned by this deletion, kept on purpose:** `Trading::Domain::WeeklyInsightCalculator` and
  the `RecentNews` / `TrendingAssets` / `MajorIndices` queries now have **zero production callers**
  (their specs still pass). Slice 4 and the asset detail may consume them; if they do not, they are
  the next §0.5 list and should be deleted then rather than accumulating quietly.

## 4. Activos tab — Cartera vs Sigo (D9, D10)

**Status:** surface shipped (slice 2a). The trade sheet and the FX block are NOT in it — see below.

- ✅ `/assets` with the `Cartera | Sigo` segmented control, reading `open_positions` and
  `watchlist_items`. Never one merged list.
- ✅ `/tracked` — the third tier with the `DAILY_BUDGET` visible, per-asset pause/resume and the
  one-tap crossing into Sigo. The budget moved out of `SyncAllFundamentalsJob` into
  `MarketData::Domain::FundamentalsBudget`, so the screen and the job read one calculation.
- ✅ `watchlist_items.entry_price` renders as "sigues +X%" — captured on every add since it
  shipped, never once displayed until now.
- ✅ Money per D10; the 🐞 in `dashboard/_watchlist_table` ("Tus posiciones" over the watchlist)
  is fixed.
- ✅ **Trade sheet (D11) — slice 2c.** `/trades/new` is a real page inside a Turbo Frame,
  presented as a native `<dialog>`: bottom-anchored on a phone, centred on desktop. Turbo drives
  the navigation (`data-turbo-action="advance"` on the link, not the frame — setting `frame.src`
  by hand skips the history push), so the back button closes it for free and the form still works
  if the JS never runs. `max-height: min(85dvh, var(--sheet-viewport-height))`, sticky Total +
  Guardar footer, `visualViewport` listener, `env(safe-area-inset-bottom)`, native
  `<input type="date">`, `inputmode="decimal"`, no drag-to-dismiss. The FX field auto-fills with
  the Banxico FIX **for the date entered** — the data-entry win and the correctness fix in one
  field, which is only possible because slice 2b shipped the history.
- ⬜ **"Guardar y registrar otro"** is drawn and not built. It is a real answer to the data-entry
  fastidio, but it needs the submit to re-open the sheet cleanly; it did not ride along as a side
  effect.
- ⬜ **`/admin/assets` is only half absorbed.** Rastreados took the list, the tiers, the budget
  and pause/resume; creating, searching and deleting assets stayed behind. Both screens exist
  meanwhile, and the admin one is reachable only by URL.
- ⚠ **Not drawn, deliberately: the state chip and the confluence dots.** The chip's taxonomy
  ("neutral", "estirado") exists nowhere in code — `trend_strength_label` measures trend strength,
  a different thing — and the semáforo is D3, whose engine is gated.
- 🐞 **`Portfolio#convert` raises on a missing FX rate, and two live screens 500 because of it.**
  With one USD position, `preferred_currency: "MXN"` and no `fx_rates` row, `/dashboard` and
  `/portfolio` both raise — today, on master. That is the product's central case on a fresh
  instance whose FX job has not run. Activos degrades instead (rows fall back to their own
  currency with the ISO prefix D10 already prescribes, and the screen says it cannot consolidate);
  the other two are fixed where they are rewritten — `/portfolio` is replaced by this screen and
  `/dashboard` by slice 3.

- Measure before landing: `grep -rn "watchlist" app/views | wc -l` and `grep -rn "Tus posiciones" app/views`
  — the second currently returns [`app/views/dashboard/_watchlist_table.html.erb`](../app/views/dashboard/_watchlist_table.html.erb),
  which titles the **watchlist** as positions (the 🐞 in D9).
- Split the surface the way the design does: one `Activos` route with a segmented control —
  `Cartera` reads `portfolio.open_positions`, `Sigo` reads `watchlist_items`. Never one merged list.
- Third tier `Rastreados` = `Asset.syncing`, its own screen (not a peer tab). It absorbs
  `/admin/assets` — same list, same `toggle_status`/`trigger_sync` actions, minus the admin costume
  (D5 killed that framing for a single-user instance). Surface the priority ladder honestly: the
  `DAILY_BUDGET = 25` split across positions → watchlist → rest, straight from
  `SyncAllFundamentalsJob#prioritized_assets`.
- Tier transitions are one tap in both directions and name what they buy (following → watchlist
  sentiment + news/earnings filters; owning → dividends and splits sync at all).
- Surface `watchlist_items.entry_price` as "sigues +X%" — the column exists and nothing renders it today.
- Money format per D10: section header declares the currency, rows drop the symbol; off-currency
  values keep the ISO prefix from `format_currency_mx`.
- Trade sheet: auto-fill the Banxico FX for the trade date and persist it as `fx_rate_at_execution`
  (the multi-currency P0 and the data-entry fastidio are the same commit).
- Trade sheet mechanics per D11 — this is where the mobile browser bites: native `<dialog>`,
  `max-height: 85dvh`, internal scroll with a **sticky Total + Guardar footer**, `visualViewport`
  listener instead of `bottom: 0`, `env(safe-area-inset-bottom)`, `<input type="date">` and
  `inputmode="decimal"`. The `Con teclado` artboard is the acceptance target, not the clean one.

**Precondition — the project has no JS-capable test driver.** All ~40 system specs run on
`rack_test`, so none of the 27 Stimulus controllers has ever been executed by a test. This slice
is the first that ships JS which can genuinely break, so the decision lands here rather than in
pre-work, where it would have been infrastructure with no consumer.

- **Recommendation: `cuprite`** (ferrum, CDP directly — no chromedriver, no selenium). Budget it
  at the 5-8 system specs for flows that actually depend on JS. **Do not convert the existing
  ~40** — on `rack_test` they are fast and test what they should.
- **What a headless driver does NOT buy: D11's acceptance.** The iOS Safari keyboard covering a
  `bottom: 0` footer, `dvh` collapsing with the address bar, `env(safe-area-inset-bottom)` — none
  of it reproduces in headless Chrome on Linux. The `Con teclado` artboard is verified on a real
  phone, the way `design/references/` captures already work. The driver buys mechanical
  regressions: does the `<dialog>` open, does the Turbo Frame load, does the form submit.
- **Rejected: Node + vitest** for unit-testing the controllers. The project runs importmap
  precisely to keep Node out of the asset chain; adding it through the test door pays for a whole
  build chain for a handful of controllers.

### ⚠ Routing constraint found while building this (2026-08-24)

**Propshaft owns `/assets`, and it only lets the exact path through.** `/assets` reaches the
controller; `/assets/anything` is swallowed and 404s **even though the router recognises it** —
verified: `recognize_path("/assets/tracked")` returns `{controller: "assets", action: "tracked"}`
and the request still returns `404 Not found`.

So D21's four tab paths are fine, but **no screen may nest under `/assets/`**. Rastreados lives at
`/tracked`, and its toggle at `/tracked/:id/toggle_sync`. The trade sheet is unaffected — D11
already puts it at `/trades/new`.

The alternative — moving `config.assets.prefix` — was rejected: it changes every asset URL, and in
production those sit behind a Cloudflare Tunnel whose cache rules key on the path.

## 5. Consolidado — "¿Valió la pena?" (D12)

**Status:** pending — design done (`flows/cockpit.pen`), engine gated on a 4-filter card.

- Reuse as-is: `Trading::Domain::PortfolioSummary`, `PeriodReturnsCalculator#chart_data`,
  `Portfolio#allocation_by_asset_type` / `#allocation_by_sector`, daily `portfolio_snapshots`.
- ✅ **The TWR engine exists** — `Trading::Domain::TimeWeightedReturn`, with flow valuation shared
  with `day_gain` through `Trading::Domain::ExternalFlows`. A spec compares it against the
  money-weighted figure on D12's own scenario.
- ✅ **The CETES benchmark has its rates** (D28). This section said the benchmark "needs no new
  gateway" — true and incomplete: `fetch_auctions` asked for `datos/oportuno`, the latest auction
  only, and nothing persisted a history. `fetch_auction_series` + `cetes_rate_histories` +
  `CetesReinvestedReturn` now cover it, following the pattern slice 2b built for FX.
- ⬜ **What is left of this slice: the screen.** All four blocks have their data — the strip, the
  two-series chart (where `lightweight-charts` finally earns its debut), both comparison cards, and
  the allocation donut. One conflict to settle when it is built: the artboard's strip shows
  **"Invertido / Disponible"**, and `Disponible` was `buying_power`, deleted by D26.
- ✅ **D27 is fixed — both halves, on `fix/snapshot-history-alignment`.** `day_gain` subtracts the
  day's external flows, `executed_at` is bounded at today, and `RebuildSnapshots` rewrites the
  history from the trades whenever one is recorded, edited or discarded with a past date. So the
  snapshot history and the trades now describe the same portfolio, which is what TWR needs.
- ✅ **D26 is fixed too — the cash concept is deleted.** `buying_power` and
  `portfolio_snapshots.cash_value` are dropped, so `total_value` is `invested_value`. The north star
  is *investment* patrimony; modelling deposits would have been a feature with no trigger. **Slice 4
  now has its floor**: the history is consistent with the trades, and the total means one thing.
- 🔴 **Two blockers, not one — measured 2026-08-24 (D26, D27).** The TWR problem below is real, and
  the remedy this section proposed for it is not: **nothing ever writes `buying_power`**, so
  `portfolio_snapshots.cash_value` is a constant and carries no flow information. The flows live in
  `trades` (no cash model ⇒ every buy is an inflow), already valued historically by
  `fx_rate_at_execution`. **But underneath that: the snapshot history is never rebuilt.**
  `TakeSnapshotsJob` writes only today's row, nothing backfills, and the trade sheet accepts any
  `executed_at` — reproduced: a buy dated five days ago leaves that day's snapshot at
  `total_value=0.0` while the portfolio holds 1,000 today. TWR compares `V_t` against
  `V_{t-1} + flow`; both sides must describe the same portfolio. Fixing TWR alone only changes which
  wrong number ships. This also collides with the 2.0's own data-entry plan, since importing history
  *is* bulk-inserting backdated trades.
- 🔴 **Do not reuse `PeriodReturnsCalculator` figures for the comparison cards.** They are
  money-weighted (current total vs an older snapshot), so a deposit inflates them. Derive TWR from
  `portfolio_snapshots.cash_value` / `invested_value` flows first; the two cards are only honest on
  top of that. Measure before building:
  `grep -rn "period_returns" app | wc -l` — every current consumer is a display of the
  money-weighted figure and stays valid; the new one is not a display, it is a claim.

## 6. Reglas y avisos (D13, D14) — DONE, except the bell

**Status:** design done (`flows/alerts.pen`); the code fixes shipped in this same PR.

- ✅ `alert_preferences.sms_notifications` renamed to `urgent_email`. Nothing ever sent SMS —
  no Twilio, no gem, no code path — while the alerts screen already called the same boolean
  "Avisos urgentes por correo". Both screens now say the same true thing.
- ✅ `Alerts::Handlers::CreateNotificationOnAlert` rewritten through
  `Alerts::Domain::TriggerNotice`: fact in the title, provenance in the body, never a bare
  amount. It lives in the domain because a background handler has no view context.
- ✅ `AlertsHelper#alert_rule_kind_label` reads the `Asset` when one exists, so a crypto rule
  is no longer labelled "Acción"; the symbol heuristic stays as the fallback for rules that
  outlived their asset. Memoized per request — the spec pins the query count.
- ✅ **The TopBar bell now has a destination.** It links to `/notifications` in both shell
  variants, and carries the unread count as its accessible name rather than a bare icon plus a
  silent dot. The dropdown panel it used to open is gone — D13 made the inbox a screen.

## 6b. The shell (slice 1) — DONE

**Status:** shipped. `app.html.erb` composes four partials: `components/_top_bar` (mobile: logo +
bell), `components/_sidebar_nav` (desktop: the four destinations), `components/_top_bar_desktop`
(desktop: screen title + bell) and `components/_bottom_nav` (mobile tabs). Both variants render;
CSS picks. `NavigationHelper` owns the four destinations so nothing is duplicated between them.

- **`admin.html.erb` is gone**, with `_admin_sidebar` and `_admin_header`. `Admin::BaseController`
  dropped its `layout` line and inherits `app`, so the admin screens render in the same shell as
  everything else until D5 folds them into Ajustes. Its hardcoded footer claiming "API Gateway:
  Operational · Database: Healthy" — never wired to a health check — went with it.
- **Routes are the ones that exist today.** Activos → `/portfolio` and Ajustes → `/profile`;
  slices 2 and 6 move them to `/assets` and `/settings`. A tab lights up per *controller*, not per
  path, so `/trades` keeps Activos lit.
- **The nav went from six entries to four.** `/market`, `/earnings` and `/news` stay routable with
  no entry point, per Adrian's call; `/search` joins them, because the redesigned TopBar has no
  search and Activos › Rastreados (its new home) is not built. Three specs pin this so it reads as
  a decision rather than rot.
- **The shell title is not an `h1`.** Every screen still owns its heading, and two `h1`s per page
  is a defect — the first draft shipped one. When a slice moves its title into the bar, that
  screen drops its heading and the bar's becomes the `h1`.
- Copy goes through I18n (`nav.*`), the first surface to do so under ADR-011.

## 7. Delivery channels (D16) — DONE, except one leftover

`AlertMailer` (digest + urgent), `SendDailyDigestJob` scheduled at `30 0 * * *` (18:30 CDMX
year-round — Mexico dropped DST in 2022), `Notifications::Handlers::SendUrgentEmail` on
`NotificationCreated`, and both preference screens reduced to the two channels that actually
deliver.

**Leftover:** `alert_preferences.browser_push` is now unused — the in-app bell cannot be turned
off, so the switch was removed rather than left lying. Drop the column when D16 settles whether a
real push channel revives it; a migration to delete it now would have to be undone if it does.

## 8. Ajustes — one hub, and two switches that must start working (D17, D18)

**Status:** pending — design done (`flows/settings.pen`), no code touched.

- Measure before landing: `grep -rn "auto_sync_enabled\|email_notifications_enabled" app lib | grep -v settings_controller`
  — today that returns **nothing outside the screen that sets them**. That is the bug.
- Merge `/profile` and the `/admin` zone into one `Ajustes` with sections. On a single-user
  instance the admin split is a costume (D5); the asset catalogue already left for Activos (D9)
  and the notification panel is down to two channels (D16).
- 🔴 **Precondition for the `Estado y mantenimiento` screen:** wire the two dead toggles before
  implementing it, or the redesign ships the same lie it documents. `auto_sync_enabled` guards the
  recurring jobs; `email_notifications_enabled` guards `ApplicationMailer` — which means the digest
  and the urgent alert from §7 must consult it too.
- Keep the audit trail: `SiteConfigChange` already records who flipped what and when, and the
  design surfaces it as "Cambios recientes".
- D18 is settled for now — pools stay, so the Integraciones screen keeps the per-provider key
  count and the rotation note. Revisit only with measured quota evidence.

## 9. Alpaca as a data source (D19)

**Status:** pending — designed in `flows/settings.pen`, needs its own 4-filter card before build.

- New gateway alongside the existing ones, following `MarketData::Gateways::*` and registered
  through `DataSourceRegistry` like the rest. Measure first:
  `grep -rn "PolygonGateway" app | wc -l` — Polygon is the intended replacement for price history.
- **Always pass `feed=sip` on historical requests.** The default for a free account is IEX
  (~2.5% of US volume); taking the default would store daily closes that are not the official
  close and quietly misvalue every USD position. SIP is free for queries whose `end` is at least
  15 minutes old, which a daily bar always is.
- Free-plan envelope: 200 req/min, 7+ years of history, crypto through `/v1beta3`.
- Use the **market-data API only**. Alpaca is a broker; trade execution is a project non-goal, and
  the key stored in this instance must not carry trading permissions.
- No coverage for fundamentals, BMV equities or CETES — those stay where they are.
