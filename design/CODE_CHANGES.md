# Code changes — landing the redesign in code

> The WORK ORDER for landing design-side decisions in code. A `Dn` entry in
> [DECISIONS.md](DECISIONS.md) records the finding + decision; this doc tracks its **execution**.
> Because this is a redesign, the kit leads the code — each section flips the kit from "ahead of
> code" to "1:1 mirror" once it ships.

**Rule: consolidation/adoption decisions cite MEASURED usage, not impressions.** Lead each section
with grep counts.

**Section statuses re-read against the tree 2026-08-27.** Every `**Status:**` line below was checked
against the code it describes, not against the last thing written about it. Three were false — §8's
D18 clause, §9 and §10 — and each carries a dated note saying what it used to claim. A status line
here is only as current as its own date, so date the correction rather than overwriting the claim.

> **Vocabulary renamed 2026-08-27 (D48).** The tier ladder is **Holdings** (was Poseo),
> **Watchlist** (was Sigo) and **Tracked** (was Rastreados); the observation sense of *movimiento*
> is **Señales**, and *movimiento* alone means a trade. Sections below still read `Sigo` and
> `Rastreados` because that is what the code and the artboards still say — the rename lands as its
> own change. Do not read the old names here as the settled vocabulary.

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
`user_activity`, `invite_code` and `remember_token` are gone.

**Updated 2026-08-27:** this paragraph ended *"only `api_key_pool` remains, and D18 keeps it
deliberately"*. D18 reversed on 2026-08-26 under
[ADR-015](../docs/architecture/adr/0015-one-api-key-per-provider.md) and the model is gone —
neither `api_key_pool` nor `KeyRotation` exists in the tree. See §8.

**Not pre-work:** consolidating the layouts (it falls out of the shell slice) and any broader
refactor — the suite is green and moving code no screen has asked for is risk without payoff.
(A coverage percentage stood here and was removed 2026-08-27: this document does not measure
coverage, so a number it copied once could only rot. The suite's real figure is whatever the
current run reports.)

## 0b. Verifications owed — none of these are code, all of them are real

Everything below shipped and passed its gates. These are the checks a machine in
this container could not perform, listed so they are not mistaken for done.

| What | Why it is still open | How to close it |
|---|---|---|
| **The typography, visually** | Until §0.2 no font resolved: `font-mono` fell back to ui-monospace across 175 sites and Inter never applied to `<body>`. The fix changes how the whole app looks and **no human has seen it**. | `bin/dev`, look at a data-heavy screen in both themes |
| **The trade sheet on a real phone** | D11 exists because the iOS keyboard covers a bottom-anchored sheet. That does not reproduce in headless Chrome on Linux, so the five specs prove the mechanism and not the reason. | Open `/trades/new` on an iPhone, focus a numeric field, confirm Total + Guardar stay reachable. The `Con teclado` artboard is the acceptance target |
| **`/assets` behind Cloudflare** | Propshaft owns that prefix. If the tunnel caches `/assets/*` as static, an authenticated page could be cached at the edge. Verified in test, never in production. | `curl -sI https://stockerly.notdefined.dev/assets \| grep -i cf-cache-status` — a `HIT` on an authenticated page means excluding the path or moving the route |

## 1. New `@theme` token values (D1)

**Status:** shipped, and it turned out to be a no-op on colour. D1 converged the design on the
code's Lumen values, so the `@theme` swap this section planned never had to happen; what did land
is §0.2's three font tokens (`--font-display / --font-sans / --font-mono`), which carry the visual
change on their own.

- ✅ **The token contract held, so nothing was renamed.** The measurement this section asked for
  (`grep -rc "bg-bg-\|text-fg-\|border-border-\|bg-positive\|bg-negative" app/views`) confirmed the
  names in use, and D1 kept the values — so `app/assets/tailwind/application.css` `@theme { }` was
  added to, not swapped.
- ✅ **The three font tokens are the whole delta**, per §0.2.

## 2. Chart component (D2)

**Status:** shipped, in the Consolidado rather than here. `lightweight-charts` is pinned at 5.2.1
and vendored; the controller generalized from `price_chart` to `chart`, taking an array of series,
and the asset detail reuses it with one.

- ✅ **No TradingView iframe.** `lightweight-charts` is pinned in `config/importmap.rb` and vendored
  at `vendor/javascript/lightweight-charts.js`, fed by our own close series — the same data behind
  RSI/Bollinger/SMA.
- ✅ **`PriceChartController` became `ChartController`.** Written in §0.4 for one series, generalized
  when the Consolidado needed two (portfolio vs CETES benchmark); the asset detail passes one.
- 🐞 **It did not debut in the Panorama, and should not have** — see §3. A 60×20px sparkline is the
  wrong job for a controller built around grid, axes and a `timeScale`.

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
- ✅ **The orphan list came due, and it is deleted.** This bullet kept
  `Trading::Domain::WeeklyInsightCalculator` and the `RecentNews` / `TrendingAssets` /
  `MajorIndices` queries in case slices 4 and 5 consumed them. They did not, so all four are gone —
  along with `NewsArticle.recent`, whose only production wrapper was `RecentNews`, and
  `BroadcastFundamentalsUpdate` (see COMPONENT_INVENTORY.md). Deleted 2026-08-25 on
  `chore/delete-dead-code`; 2671 examples, 0 failures.

## 3b. Asset detail (slice 5) — DONE, with the header left alone

**Status:** shipped. `/market/:symbol` carries two tabs: `Análisis` and `Mi posición`, the second
only when you hold the asset.

- ✅ **The TradingView widget is gone.** It loaded a script from `s3.tradingview.com` and handed it
  the symbol being viewed — D2 rejected the iframe for the redesign and nobody removed the one
  already shipping. Our own closes render it now. A spec fails if any wiring reappears.
- ✅ **The verdict card** reads the state out loud under
  [ADR-014](../docs/architecture/adr/0014-state-phrases-from-a-closed-catalogue.md): a closed
  catalogue keyed by a state derived from persisted observations, with the reading kept beside it.
- ✅ **`PositionBreakdown` splits the gain between the asset and the peso** — the MXN-first
  differentiator. The two parts reconstruct the total exactly, verified in a spec and visible on
  screen (`+62.7%` + `+17.5%` = `+80.2%`).
- ✅ **`PurchaseRetrospective` states how you entered and stops there.** The artboard's "buen timing"
  is absent: ADR-001/013/014 all describe the market, and nothing covers the app grading its owner's
  decisions. `RsiOnDates` recomputes RSI for past buy dates and omits those without 15 closes behind
  them — `BackfillPriceHistoryJob` fetches 30 days, so a purchase predating the asset's sync has no
  answer and the block is absent rather than averaged from what survived.
- ✅ **"VS. TU PLAN" became "VS. TUS REGLAS."** The artboard's `Meta: 200` has no `target_price`
  anywhere in the code; `alert_rules` does exist, and `alert_condition_summary` already renders it.
- ✅ **The header is redesigned.** 126 lines became a back link, the name, the price and a bookmark.
  It gained `≈ MXN 3,684` — the price in the reader's own currency, which is the MXN-first point and
  did not exist before; nil rather than approximated when no rate is stored. The capture button
  moved to the foot of Mi posición, where the artboard puts it, so there is exactly one again.
  **One chip the artboard does not draw is kept on purpose:** the asset type. Exchange and currency
  were redundant (both appear below), but the type is only inferable from which blocks render, five
  specs defended it, and dropping it would leave it visible only on Rastreados. The provenance
  caption stays too — where a number came from is not decoration on a screen built to be checkable.
- ⚠ **The fundamentals block keeps its sub-tabs** inside Análisis. The artboard flattens Resumen /
  Valoración / Estados into the scroll; that restructure was not attempted here.
- ⬜ **Not built:** the confluence semáforo (D3, gated), "Cerrar posición" (an action the code does
  not have — a sell is already a movement), and the per-period `Rendimiento` block.

## 3c. Auth (design-match pass) — DONE

**Status:** shipped. The first screen brought to the artboards rather than built from them, after
Adrian's read that the site does not look much like the designs — true, and worth saying: the
slices built new screens against artboards while auth, onboarding, the market listing and alerts
stayed pre-2.0.

- ✅ **A real `auth` layout.** `layouts/auth.html.erb`: no public navbar, no footer, the card
  centred on the canvas, and the artboard's **split panel on desktop** — brand left, form right.
  Sessions and password resets moved off `layout "public"`.
- ✅ **The five screens rebuilt on tokens and i18n.** They were `slate-*` utilities and hardcoded
  es-MX; they are `border-border-default` / `text-fg-default` and `auth.*` keys now. Two shared
  partials (`_auth_field`, `_auth_header`) mean the screens cannot drift apart again.
- ⚠ **The "revisa tu correo" copy departs from the artboard on purpose.** The artboard reads *"te
  enviamos un enlace a tu@correo.com"*; naming the address confirms it is registered to anyone who
  can reach that page. The existing copy is deliberately identical whether or not the address
  exists (S11 #147), and `RequestPasswordReset` does the silent no-op. **"Reenviar enlace" returns
  to the form** rather than resending, for the same reason: a real resend needs the address held
  somewhere.
- ⚠ **Risk disclosure is no longer one click from login.** The auth layout has no public footer, and
  the artboard's terms line carries two links. It stays reachable from the legal pages.
- 🐞 **The wordmark has been cut off across the entire site.** `logo_light.svg` and `logo_dark.svg`
  declare `viewBox="0 0 130 40"`, and the text starts at `x="32"` at `font-size="22"` — roughly
  142px of artwork in a 130px box, so the final "y" was clipped everywhere the logo renders. Widened
  to 148. **Every screenshot this session showed it and I read past it each time.**
- ⬜ **2FA is not built** (D23, still gated) and `auth-2fa.png` stays an artboard. The entry's
  premise that the box "sits behind Cloudflare Tunnel and Tailscale" does not survive reading
  `config/deploy.yml` — the tunnel publishes `stockerly.notdefined.dev` publicly and no Access
  policy is recorded anywhere in the repo. Recommendation unchanged in outcome, changed in reason:
  front the hostname with **Cloudflare Access** rather than building TOTP. Recovery then runs
  through the Cloudflare account instead of an authenticator app on one device — which is the
  permanent-lockout risk D23 identified, and the reason TOTP cannot ship alone.
- ✅ **The session lasted 12 hours and idled out after 30 minutes** (D29). On a product whose north
  star is a *weekly* visit, that logged Adrian out before every single one. Now 14 days idle, 30
  days absolute, cookie at 31 so the app's check fires and says why. The old pair had a real bug
  underneath: the cookie died at 12 hours too, so any longer app-level window was unreachable and
  the expiry redirect arrived with no message at all.
- 🐞 **Both expiry messages were English**, the only hardcoded strings left in
  `ApplicationController` — `auth.session.*` now, under ADR-011.
- ⬜ **Four more English flashes survive, all on surfaces this section named as pre-2.0.**
  `setup_controller` (*"Admin account created! Let's configure your instance."*, *"Setup already
  completed."*), `admin/onboarding_controller` (*"Setup complete! Your data is syncing."*) and
  `admin/base_controller` (*"Not authorized."*). Left deliberately: ADR-011 adopts i18n **surface by
  surface**, so writing keys for screens about to be redesigned is work the redesign would redo.
  Worth carrying into the onboarding slice — the first two also carry exclamation marks ADR-001
  forbids, and *"Admin account created"* is the admin framing D5 decided to drop.

## 4. Activos tab — Cartera vs Sigo (D9, D10)

**Status:** shipped, both halves. Slice 2a brought the surface; 2b brought the trade sheet at
`/trades/new` and the historical-FX block (`fx_rate_at_execution`, auto-filled from Banxico).

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
- ✅ **"Guardar y registrar otro" is built.** Two submits with two destinations: `Guardar` targets
  `_top`, so the response navigates and the dialog goes with it; the second stays in the frame and
  comes back empty, keeping the side the user was working in. The confirmation renders **inside** the
  sheet, because the flash lives behind the dialog and a sheet that stays open would otherwise look
  like nothing happened.
- 🐞 **Measuring it found that saving never closed the sheet.** Reproduced before touching anything:
  record a movement and the dialog stayed open with the form still filled, at `/trades/new`, with
  the flash behind it. Nothing confirmed, and pressing Guardar again recorded the same movement
  twice. Fixed by the `_top` target above.
- 🐞 **The success turbo_stream prepended to `#trade_history`, which nothing that could submit the
  form mounts.** `/trades` and `/positions` have the tbody but no create form; the sheet lives on
  Activos and Mi posición, which have neither. Same shape as `_asset_fundamentals` in §0.5 — a
  stream into a target no page mounts, with a spec that passed by asserting the stream's body.
- ✅ **`/admin/assets` is fully absorbed — 2026-08-26 (D34).** Rastreados had the list, the tiers,
  the budget and pause/resume; adding and removing an asset landed there too, with the same ticker
  typeahead, and the admin screen was deleted. Measured before moving rather than assumed:
  `assets#toggle_sync` already called `Administration::UseCases::Assets::ToggleStatus`, so
  `toggle_status` was the same action drawn twice. `trigger_sync`, `UpdateAsset` and the catalogue
  filters were dropped on the record — see D34 for why each.
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
  `/admin/assets` — same list, same `toggle_status` action, minus the admin costume
  (D5 killed that framing for a single-user instance; D34 finished the absorption and deleted the
  screen). Surface the priority ladder honestly: the
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

**Status:** shipped. `/portfolio` is the Consolidado. The engine is no longer gated — TWR and the
CETES rate series both landed (D12, D28), and D26/D27 cleared the floor underneath them.

- Reuse as-is: `Trading::Domain::PortfolioSummary`, `PeriodReturnsCalculator#chart_data`,
  `Portfolio#allocation_by_asset_type` / `#allocation_by_sector`, daily `portfolio_snapshots`.
- ✅ **The TWR engine exists** — `Trading::Domain::TimeWeightedReturn`, with flow valuation shared
  with `day_gain` through `Trading::Domain::ExternalFlows`. A spec compares it against the
  money-weighted figure on D12's own scenario.
- ✅ **The CETES benchmark has its rates** (D28). This section said the benchmark "needs no new
  gateway" — true and incomplete: `fetch_auctions` asked for `datos/oportuno`, the latest auction
  only, and nothing persisted a history. `fetch_auction_series` + `cetes_rate_histories` +
  `CetesReinvestedReturn` now cover it, following the pattern slice 2b built for FX.
- ✅ **The screen shipped.** `/portfolio` is the Consolidado: the strip, the two-series chart, both
  comparison cards and the allocation donut. **`lightweight-charts` debuts here** — the controller
  generalized from `price_chart` to `chart`, taking an array of series, which the asset detail will
  reuse with one.
- ✅ **The strip conflict is settled the only way D26 allows.** The artboard draws
  "Invertido / Disponible"; `Disponible` was `buying_power`. The split is gone and the strip carries
  the total and the day's move.
- ✅ **The four lists moved to `/positions`** — open, closed, dividends and the trade log — routable
  with no nav entry, the slice-1 treatment. The S09 KPI strip, the inline trade form and the tabbed
  allocation sidebar died with the old screen; the sheet at `/trades/new` and this donut replace
  them. `TradesController` now lands on Activos, where capture lives.
- 🐞 **Found by the screenshot, fixed here: the allocation donut has never drawn a coloured ring in
  light mode.** Tailwind 4 tree-shakes `@theme`, and nothing generates a `bg-chart-3` utility — so
  `--color-chart-2..8` were emitted only inside the dark block, which is ordinary CSS. The data-viz
  tokens moved to `@theme static`. Every screen that reads `var(--color-chart-N)` was affected; only
  light mode showed it.
- ⬜ **What is left of this slice: nothing.**
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
- 🐞 **The rename missed `db/seeds.rb`, and nothing could have caught it.** The demo-user block
  kept assigning `sms_notifications`, so `bin/rails db:seed` raised `UnknownAttributeError` —
  invisible to a green suite, because the block is guarded by `Rails.env.development?` and CI never
  runs `db:seed`. Fixed 2026-08-25. Worth remembering that a first boot with a seeded demo is
  exactly what the 2.0 promises a self-hoster.
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
bell), `components/_sidebar_nav` (desktop nav), `components/_top_bar_desktop` (desktop: screen
title + bell) and `components/_bottom_nav` (mobile tabs). Both variants render; CSS picks.
`NavigationHelper` owns the destination list so nothing is duplicated between them.

> **Count corrected 2026-08-27.** This section said "the four destinations" twice, and
> [`navigation_helper.rb`](../app/helpers/navigation_helper.rb) has carried **five** since §10
> landed — Panorama · Activos · Reglas · **Descubrir** · Ajustes, with Descubrir at index 3 per
> D31. Four was true when the shell shipped; nothing re-read it when the fifth arrived. The rest
> of this section is left as written.

- **`admin.html.erb` is gone**, with `_admin_sidebar` and `_admin_header`. `Admin::BaseController`
  dropped its `layout` line and inherits `app`, so the admin screens render in the same shell as
  everything else until D5 folds them into Ajustes. Its hardcoded footer claiming "API Gateway:
  Operational · Database: Healthy" — never wired to a health check — went with it.
- **Routes are the ones that exist today.** Activos → `/portfolio` and Ajustes → `/profile`;
  slices 2 and 6 move them to `/assets` and `/settings`. A tab lights up per *controller*, not per
  path, so `/trades` keeps Activos lit.
- **The nav went from six entries to four** — and to five on 2026-08-27, see the note above.
  `/market`, `/earnings` and `/news` stayed routable
  with no entry point, per Adrian's call; `/search` joined them, because the redesigned TopBar has
  no search and Activos › Rastreados (its new home) is not built. Three specs pinned this so it
  read as a decision rather than rot.
  **Settled 2026-08-26 (D31/D35):** routable-and-unlisted was a holding pattern, not a destination.
  `/earnings`, `/news`, `/market`'s listing and `/search` are deleted; `/market/:symbol` stays and
  its back arrow now points at Activos. The specs that pinned "no entry point" now pin "no route".
- **The shell title is not an `h1`.** Every screen still owns its heading, and two `h1`s per page
  is a defect — the first draft shipped one. When a slice moves its title into the bar, that
  screen drops its heading and the bar's becomes the `h1`.
- Copy goes through I18n (`nav.*`), the first surface to do so under ADR-011.

- **The bell badge is a dot in code and a count in the design (D32.3).** [`components/_top_bar.html.erb`](../app/views/components/_top_bar.html.erb) renders a bare dot when `navbar_unread_count.positive?`; `alerts.pen` draws `BellWrap > Bell + Badge` with a number in it. Design leads per D8, so landing it means rendering `navbar_unread_count` inside the badge and deciding what happens past 9 (`9+` is the usual answer). `navbar_unread_count` already computes and memoises it, and both partials already call it twice — once for the `aria-label`, once for `.positive?` — so the **number is available and simply never painted**: this costs a span, not a query. It lands in **two** files, `_top_bar.html.erb` and `_top_bar_desktop.html.erb`. The kit's own `TopBar` has neither, which is the gap D32.3 leaves for the next promotion batch.

## 7. Delivery channels (D16) — DONE, except one leftover

`AlertMailer` (digest + urgent), `SendDailyDigestJob` scheduled at `30 0 * * *` (18:30 CDMX
year-round — Mexico dropped DST in 2022), `Notifications::Handlers::SendUrgentEmail` on
`NotificationCreated`, and both preference screens reduced to the two channels that actually
deliver.

**Leftover, now settled (2026-08-25).** `alert_preferences.browser_push` was unused — the in-app
bell cannot be turned off, so the switch was removed rather than left lying, and this section kept
the column pending D16. The Reglas rebuild forced the call, because `reglas-lista` draws a bell
toggle: **the column is dropped.**

What decided it was that the design already disagreed with itself. `ajustes-hub` writes *"Todo
aviso llega a tu campana; **eso no se apaga**. El correo sí."* and draws two switches;
`reglas-lista` draws three and gives the first one to the bell. Ajustes had it right, and the code
had aligned with that half.

Measured before dropping: no `web-push`-class gem, no VAPID pair, no `push_subscriptions` table,
and the service worker's `push` listener is still the commented scaffold Rails generates. The
"interrupt me" channel already exists and delivers — `AlertMailer#urgent_alert`, fired by
`SendUrgentEmail` on `NotificationCreated`.

**If push is revived**, the migration is reversible and Adrian's starting reference is
[Joy of Rails — Web push notifications from Rails](https://joyofrails.com/articles/web-push-notifications-from-rails).
Worth knowing going in: on iOS, Web Push only reaches a PWA installed to the home screen, so on a
mobile-first product it is a channel that can fail silently on the primary device — which is the
defect this section existed to remove. It needs its own 4-filter card.

## 8. Ajustes — one hub, and two switches that must start working (D17, D18)

**Status:** shipped. The hub is at `/settings` and both switches are wired (D17). What is left is
visual: the four instance screens keep their admin styling.

- Measure before landing: `grep -rn "auto_sync_enabled\|email_notifications_enabled" app lib | grep -v settings_controller`
  — today that returns **nothing outside the screen that sets them**. That is the bug.
- ✅ **The hub shipped at `/settings`**, and the nav's Ajustes points there. Sections: the account
  card, Cuenta (name/email and password, linking to `/profile` which already holds those forms),
  Apariencia y región (theme and currency), Avisos, Tu instancia, Tus datos, and sign-out.
- ✅ **It links to the instance surfaces rather than reimplementing them** — Integraciones, Registros,
  Estado y mantenimiento and Mission Control all keep their existing screens. D5's point was killing
  the admin *framing*, not rewriting four working pages.
- ⚠ **No failed-jobs badge.** The artboard shows a count beside Trabajos; `SolidQueue::FailedExecution`
  lives in another database and counting it put a cross-database query in the hub's request path —
  which aborted the transaction outright in test. Mission Control shows the real number on open.
- 🐞 **Found by the screenshot: the currency control listed USD before MXN**, because
  `Asset::SUPPORTED_CURRENCIES` is ordered for validation and the view iterated it. On an MXN-first
  product the local currency reads first.
- ⬜ **Left as they are:** `/profile` keeps its tabs and remains the destination for name, email and
  password; the four instance screens keep their admin styling. Folding those into the hub's visual
  language is a further pass.
- Merge `/profile` and the `/admin` zone into one `Ajustes` with sections. On a single-user
  instance the admin split is a costume (D5); the asset catalogue already left for Activos (D9)
  and the notification panel is down to two channels (D16).
- ✅ **The precondition is met: both toggles are wired** (D17). `auto_sync_enabled` guards the 24
  jobs that go out to the network for market data, through a `PausableSync` concern — local
  computation (trend scores, observations, snapshots) keeps running, because with no new data it is
  a no-op and stopping it would make the switch mean more than its label says. Notification jobs are
  out for the same reason.
  `email_notifications_enabled` guards `AlertMailer`'s digest and urgent alert — **deliberately not
  `ApplicationMailer`**: `UserMailer#password_reset` is the way back into an account, and a
  single-user instance with no support desk cannot afford a settings switch that locks its owner
  out. Both default to **on** when the row is absent, so an instance predating the wiring does not
  go quiet; specs pin that default, which is the part that would have been catastrophic to get
  wrong.
- Keep the audit trail: `SiteConfigChange` already records who flipped what and when, and the
  design surfaces it as "Cambios recientes".
- ~~D18 is settled for now — pools stay, so the Integraciones screen keeps the per-provider key
  count and the rotation note. Revisit only with measured quota evidence.~~

  **Reversed 2026-08-26 — [ADR-015](../docs/architecture/adr/0015-one-api-key-per-provider.md):
  one API key per provider.** The line above is kept struck rather than deleted because the
  reversal did not arrive on the axis D18 named. D18 said *delete if the quotas turn out
  comfortable*; what actually decided it was the 2026-08 provider audit reading the terms —
  **Alpaca, Massive (ex-Polygon), Finnhub and CoinGecko each prohibit using multiple accounts or
  credentials to exceed a free tier.** The pool bought Alpha Vantage 25 → 50 calls a day and risked
  account termination in a product other people run on their own credentials.

  **Implication for this screen, reversing the sentence above: Integraciones loses the per-provider
  key count and the rotation note, and shows one key per provider.** Verified in the tree
  2026-08-27 — `api_key_pool` and `KeyRotation` are gone, and
  `admin/integrations/_provider_card.html.erb` renders a single `api_key_encrypted` field with no
  count and no rotation copy. Renaming the mechanism to "primary + fallback key" was considered and
  rejected: the terms bind conduct, not labels. The artboard is the side still to catch up.

## 9. Alpaca as a data source (D19) — SHIPPED

**Status:** shipped, [#290](https://github.com/rodacato/stockerly/issues/290) closed. This section
read *"pending — needs its own 4-filter card before build"* until 2026-08-27, by which point the
gateway had been in the tree long enough for §10 to be built on top of it and for FIDELITY_AUDIT to
already record #290 as closed. Verified rather than assumed:
[`app/contexts/market_data/gateways/alpaca_gateway.rb`](../app/contexts/market_data/gateways/alpaca_gateway.rb)
exists and `config/initializers/data_sources.rb` registers `:alpaca_us` with
`gateway_class: MarketData::Gateways::AlpacaGateway` and `circuit_breaker_key: "alpaca"`. Six jobs
call it. The constraints below are the build's contract and are kept as the record of what it must
keep doing.

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

## 9b. Onboarding (slice 7) — SHIPPED

> **Renumbered 2026-08-27.** This section and Descubrir were **both numbered §10**, so every
> reference to "§10" was ambiguous — including the design README's pointer here. Descubrir keeps
> §10 because DECISIONS.md D33 and `ui-kit.CHANGELOG.md` both cite `§10.x` sub-items by number and
> neither is this document's to edit. This one takes **§9b**, which is the file's own convention
> for a section inserted later (§0b, §3b, §3c, §6b are all that, and none is a sub-part of its
> parent number).

**Status:** shipped 2026-08-25. Measured first, and the measurement is kept below because it is what made the slice smaller than it looked. `flows/onboarding.pen` is **done · in review** with
**9 artboards** (setup, integrations, assets, complete, welcome, plus 4 desktop) and this document
had no section for it — the only entry in the design README without a row here.

The four views **were** pre-2.0 when this was written, counted in utilities. The paths in the first
column no longer exist: the wizard left `Admin::` with this slice, and the views live at
`app/views/onboarding/` now (`setup/new` stayed put). Re-measured 2026-08-27, `onboarding` is
0 slate / 40 tokens / 27 i18n and `setup` is 0 / 2 / 12 — the table below is the **before**, kept
because "what shipped" further down is scored against it.

| View (path as of 2026-08-24) | `slate-*` / `gray-*` | Lumen tokens | i18n keys |
|---|---|---|---|
| `admin/onboarding/assets` → `onboarding/assets` | 14 | 0 | 0 |
| `admin/onboarding/complete` → `onboarding/complete` | 14 | 3 | 0 |
| `admin/onboarding/integrations` → `onboarding/integrations` | 15 | 2 | 0 |
| `setup/new` | 10 | 1 | 0 |

It matters beyond consistency: the vision's second success criterion is *"un tercero técnico lo
levanta, carga su primer activo y lee su primer indicador sin fastidio"*, and this is that path.

### What the measurement found

- 🐞 **`/welcome` is unreachable, and it is already the artboard.**
  [`authenticated_controller.rb:22-25`](../app/controllers/authenticated_controller.rb#L22-L25)
  branches the onboarding on `current_user.admin?` — admins to the wizard, everyone else to
  `/welcome`. **Nobody else can exist.** The only path that creates a user is
  `Identity::UseCases::CreateFirstAdmin`, which hard-codes `role: :admin` and refuses once any user
  exists; the pivot deleted registration and there is no other route. So the `else` branch is dead
  and `/welcome` is orphaned — **while its view already matches `onboarding-welcome.png` copy for
  copy** (S07 built it; the artboard was drawn from it, per the flow's own working model). The
  slice does not build Welcome. It **connects** it.
- 🐞 **`welcome_spec.rb` is green against a state production cannot reach.** It builds
  `create(:user, onboarded_at: nil)` and the factory defaults to `role { :user }` — the role no
  code path produces — then requests `/welcome` directly, so it never exercises the branch that
  would have to send anyone there. The screen works; the route to it does not exist.
- 🐞 **Two use cases complete onboarding, in two bounded contexts.**
  `Administration::UseCases::Onboarding::CompleteSetup` and
  `Identity::UseCases::CompleteOnboarding` both write `onboarded_at`; the first also enqueues the
  initial sync jobs. The second is only reachable through the dead branch above.
- ⚠ **The whole flow still lives in `Admin::`** — `Admin::OnboardingController < BaseController`,
  `admin_onboarding_*` routes, views under `app/views/admin/onboarding/`, and `launch` landing on
  `admin_root_path`. **D5 decided to drop the admin framing** and §6b already deleted the
  `admin.html.erb` layout; this is what is left of the costume. The Welcome artboard's CTA reads
  *"Ir al panel"* — the Panorama, not an admin dashboard.
- ⚠ **`/setup` renders under `layout "public"`.** The design README pairs it with Login explicitly
  (*"Same split-panel as Setup — the two doors match"*), and §3c already built `layouts/auth.html.erb`
  with that split panel. The door to the instance and the door back into it should not look
  different.
- ⬜ **Three of the four English flashes recorded in §3c live here**, one of them
  *"Admin account created! Let's configure your instance."* — which violates D5's naming and
  ADR-001's voice in the same sentence.

### The 4-filter card

**D30 is settled (2026-08-25): the wizard ends at Welcome.** The metric and the DoD below were
proposed rather than supplied — Adrian delegated them and can correct any line.

1. **Trigger.** The closed beta failed on first contact: friends did not know what to do, could not
   read the indicators, and abandoned. That is documented in [[project-vision]] as the reason the
   pivot happened, and this flow is the surface where it happened.
2. **JTBD.** *When I boot a fresh instance, I want to reach a screen that tells me what to do next,
   so that I do not land on an empty dashboard and close the tab.*
3. **Usage metric (proposed).** A first boot reaches Welcome and leaves it through one of its three
   cards — record a trade, add a watch, create a rule — rather than through "Ir al panel". The
   instance already records the three; the check is whether the first one happens in the same
   session as onboarding, not whether it ever happens.
4. **Definition of Done (proposed).**
   - [ ] `launch` lands on `/welcome`, not `admin_root_path`; *"Ir al panel"* goes to the Panorama.
   - [ ] The `current_user.admin?` branch in `redirect_to_onboarding` is gone — one path, because
         there is one kind of account.
   - [ ] `Identity::UseCases::CompleteOnboarding` is retired; `CompleteSetup` is the only writer of
         `onboarded_at`, and it keeps launching the initial sync.
   - [ ] `welcome_spec` exercises the real route (wizard → Welcome) instead of requesting the path
         with a `role: :user` the app cannot create.
   - [ ] The wizard leaves `Admin::` — controller, routes and views — per D5.
   - [ ] `/setup` renders under `layouts/auth`, the split panel §3c built, so both doors match.
   - [ ] The four views are on Lumen tokens and `t(".key")` lookups; `i18n-tasks health` stays green.
   - [ ] The three English flashes here are es-MX, and *"Admin account created"* loses the framing
         D5 dropped and the exclamation mark ADR-001 forbids.
   - [ ] **Negative:** a second `/setup` visit on a provisioned instance still refuses, and no route
         in the flow is reachable once `onboarded_at` is set.

Per [[project-working-method]] the card itself belongs in a GitHub issue, not here — this section is
its discovery. The issue was never opened; the slice was built directly from this card.

### What shipped, against that DoD

Eight of the nine as written. The third **inverted**, and it had to:

- ✅ `launch` lands on `/welcome`; Welcome's CTA goes to the Panorama.
- ✅ The `admin?` branch is gone. One account, one path.
- ⚠ **`Identity::UseCases::CompleteOnboarding` is the single writer of `onboarded_at` — not
  `CompleteSetup`, which is what this card asked for.** The two criteria could not both hold:
  `WelcomeController` sends an onboarded user to the dashboard, so stamping the flag before the
  redirect makes Welcome render never. Welcome cannot become a permanent page either, because
  `/help` already renders the same `shared/_welcome_body`. So the write moved the other way, which
  is the better boundary regardless — `CompleteSetup` was an Administration use case writing a
  `User` attribute. It is `LaunchInitialSync` now and does only what it says.
- ✅ `welcome_spec` uses `:admin` and asserts the wizard is what sends you there.
- ✅ The wizard left `Admin::` — controller, routes, views. `/admin/onboarding/*` → `/onboarding/*`.
- ✅ `/setup` renders under `layouts/auth`, reusing `_auth_header` and `_auth_field` so the two
  doors share their parts rather than merely resembling each other.
- ✅ Lumen tokens and `t(".key")` throughout; `i18n-tasks health` green at 262 keys, none unused.
- ✅ The English flashes are gone. *"Setup complete! Your data is syncing."* was deleted rather than
  translated — Welcome is the confirmation now.
- ✅ The negative criterion holds, pinned by a spec that walks every step once `onboarded_at` is set.

### Three defects only the screenshots found

The green suite saw none of them, which is §3's lesson arriving on schedule.

1. **The app shell rendered around the wizard** — TopBar and the four bottom-nav tabs, mid-setup,
   offering exits that `redirect_to_onboarding` immediately undoes. The artboards draw no chrome.
   Fixed with `layouts/onboarding`: auth's principle without auth's card, since a step is
   full-width and not a form on a panel.
2. **The primary CTA was shrink-wrapped with its label spilling out of the button.** `button_to`
   puts `:class` on the button and wraps it in an inline-block form, so `w-full` measured against a
   form that had already collapsed to its content. `form_class:` is the fix.
3. **The category headings were English** — `AssetCatalog.category_label` returned "US Stocks" and
   "Cryptocurrency" from Ruby, so translating the views alone would have left them on screen.

### Found here, not fixed here

- 🐞 **`content_for(:admin_page_title)` looked like an orphan and was a broken screen.** Five admin
  views wrote it; the partial that read it went with `admin.html.erb` in §6b, and
  `Admin::BaseController` started inheriting the 2.0 shell, which reads `:page_title`. Probed rather
  than assumed: `/admin/logs` rendered **"Ajustes"** as its heading — the shell falls back to a nav
  label when no page title is set — and its tab read *"Stockerly | Navigate the Markets with
  Confidence"*, generic, English, and a tagline from before the pivot. **Converted, not deleted**:
  each view sets `:page_title` for the bar and `:title` for the tab, and a spec pins both for all
  five paths plus the absence of the dead key. Fixed 2026-08-25 with slice 7, since §6b is what
  broke it.


## 10. Descubrir — the fifth destination (D31) — SHIPPED

**Status:** shipped 2026-08-27, [#291](https://github.com/rodacato/stockerly/issues/291) and
[#292](https://github.com/rodacato/stockerly/issues/292). This section said *"build pending,
blocked on §9 (Alpaca)"* until 2026-08-27; §9 had shipped and so had this. Verified in the tree:
`config/routes.rb:52` routes `/discover`, `app/controllers/discover_controller.rb` and
`app/views/discover/show.html.erb` (142 lines) exist, `app/jobs/warm_discover_job.rb` runs
`every 4 hours` from `config/recurring.yml`, and `NavigationHelper::MAIN_NAV` carries five entries
with `discover` at index 3.

**Three blocks, not four.** The screen ships **Olas · Titulares · Calendario**. *Reportes* was
dropped from the product and from the artboards by D47 (2026-08-27) — Alpaca serves `historical`,
`news`, `dividends` and `splits`, never earnings, so the block would have put a third provider on
the screen for the least valuable of the four. It returns only with its own 4-filter card.

**Do the A cleanup first.** Deleting `market#index`, `news`, `earnings` and folding `search` into
Rastreados touches `spec/system/navigation_spec.rb`, and so does the fifth destination. Landing the
cleanup first means that file is rewritten once instead of twice.

**All seven landed.** The rows are kept as the contract the build has to keep holding, not as open
work. Two worth re-reading: **10.5** is live in `config/recurring.yml` at `every 4 hours` with the
24 h TTL the row asked for, and **10.6b** was answered — `discover/show.html.erb` renders a
`calendario_agotado` string when the file runs out, which is D33's candidate answer adopted rather
than the empty block it warned about.

| # | What | Notes |
|---|---|---|
| 10.1 | `NavigationHelper::MAIN_NAV` 4 → 5, new entry at **index 3** | Panorama / Activos / Reglas keep their position; only Ajustes shifts. Both nav partials iterate `main_nav_items`, so neither changes structurally |
| 10.2 | `_bottom_nav` layout check | Five items at `min-w-16` inside a 390 viewport fit on paper (320 + padding). Verify on a real phone, not in a headless browser |
| 10.3 | `nav.discover` in `config/locales/es-MX.yml` | ADR-011 |
| 10.4 | `spec/system/navigation_spec.rb:73` | *"navigates to the four shell destinations"* → five |
| 10.5 | `WarmDiscoverJob` + one entry in `config/recurring.yml`, every 4h | Writes with a **24h** TTL so a failed run serves stale data with "actualizado hace 6 h" rather than an empty screen |
| 10.6 | Two YAMLs, not two Ruby constants | The 17-symbol basket and the Banxico/Fed calendar. C8 Bram: hardcoded in Ruby means a self-hoster edits code and loses it on the next pull |
| 10.6b | **⏳ D33 — decide the calendar's exhausted state before shipping this block** | The YAML is settled (no automatable source: Banxico's calendar is a non-machine-readable PDF grid, the Fed's dates are labelled *tentative*). What is not settled is what the block renders once the file runs out — today's design shows an empty block on the one surface that promises to work without a credential. Open on purpose; whoever builds 10.6 owns it |
| 10.7 | `discover:last_seen` on each visit, surfaced in Ajustes › Estado | Three lines, no table. It is the evidence the kill criterion needs |

**Zero migrations.** If this section ever grows a migration, the disposability contract broke and
that is a finding, not a detail — see D31 clauses 1 and 5.

**Deletion checklist** (what "disposable" means operationally): the `discover` folder, one route,
one `MAIN_NAV` entry, one job file, one `recurring.yml` line, two YAMLs, one spec folder, one
`nav.*` key. Nothing else in `app/` may reference it.

**Kit — both halves paid, corrected 2026-08-27.** This paragraph said the fifth destination lived
*"only in `flows/discover.pen` as a local override"*, waiting on a 0.6.0 bump and a re-vendor. Both
happened: `ui-kit.CHANGELOG.md` records **0.6.0** putting Descubrir into `BottomNav` and
`SidebarNav` at index 3 (`AppShellDesktop` inherited it by `ref`), and **0.7.0** re-synced all
seven flows for the new mark. The kit is at 0.7.0. Left uncorrected, this sent a reader to redo
design work that was already done — which is the failure mode FIDELITY_AUDIT's last TODO group
exists to name.

## 11. The new mark (D45) — SHIPPED

Landed as one commit with the artwork, the manifest and every cache bust together. Kit 0.7.0 and
all seven flows carry the mark; `design/exports/` was regenerated.

| # | What | Result |
|---|---|---|
| 11.1 | `app/assets/images/logo_light.svg` + `logo_dark.svg` | Done. Symbol `1.375 x` the type size, gap `1/6` of the symbol, wordmark baseline raised so the ink block centres against the disc rather than the text box |
| 11.2 | `public/favicon.svg`, `icon.svg`, `icon-192.svg`, `icon-512.svg` | Done. Flat `#5B6CFF` plate, white mark at 70% |
| 11.3 | **NEW** `public/icon-maskable-512.svg`, manifest `purpose: maskable` repointed | Done — this was the 🐞. Full-bleed plate, no rounding, mark at 52% inside the 66.6% safe circle |
| 11.4 | `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` (180, opaque, unrounded) | Done, rasterised from the SVGs with headless chromium at 1x |
| 11.5 | `public/manifest.json` copy → es-MX | Done, plus **`id: "/dashboard"` added** — without it PWA identity derives from `start_url`, so changing that later would strand users with two installed apps |
| 11.6 | `?v=2` → `?v=3` | Done in **three** files, not the two this section predicted — see below |
| 11.7 | Specs | `logo_spec.rb` green and unedited — filenames held. **But it was not the only spec that mattered:** `spec/requests/pwa_spec.rb` pinned `?v=2` literally and went red in CI. Rewritten to pin the layout, manifest and service worker **to each other** instead of to a constant, so the next brand bump fails only if it misses a file. Two regression nets added: the maskable icon must not share a `src` with the plain one, and every `PRECACHE_URLS` entry must exist on disk |
| 11.8 | Two surfaces bypass `shared/_logo` | **Done, and the diagnosis was wrong.** The bypass was never the defect: the auth panel is always indigo so it wants a fixed variant rather than a themed one, and the mailer needs an absolute URL because mail clients cannot resolve relative ones. Both had said so in comments. What was false was the partial's claim to be the single source of truth while three files named the SVGs. `brand_logo(:light | :dark)` owns the filenames now; each caller keeps the rendering its surface needs |

**Two things this section did not predict.**

`public/service-worker.js` **also pinned `?v=2`** — it pre-caches every brand asset, so bumping only
the layout and the manifest would have left the SW serving the old logo from `stockerly-static-v4`
forever. Its `CACHE_VERSION` went `v4` → `v5` so the activate handler purges the old cache, and the
maskable icon joined `PRECACHE_URLS`. Note `cache.addAll` rejects the whole install if any URL 404s:
all eight entries were verified to exist. **The lesson generalises — grep the whole repo for the
bust token, do not trust a list.**

`app/views/pwa/manifest.json.erb` **was dead and had already drifted** — no route referenced it, not
even a commented one, and its `start_url` said `/` while the served `public/manifest.json` said
`/dashboard`. Deleted rather than updated; two manifests that disagree is worse than one.
