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

## 3. Cockpit components → ERB partials

**Status:** pending — design first.

- The `cockpit.pen` components map 1:1 to `app/views/components/`. Translate after the flow is
  approved (per README fidelity loop). Confluence engine (Light 2 + window) is NOT built here —
  gated on its 4-filter card (D3).

## 4. Activos tab — Cartera vs Sigo (D9, D10)

**Status:** pending — design done (`flows/assets.pen`), code revamp not started.

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

## 5. Consolidado — "¿Valió la pena?" (D12)

**Status:** pending — design done (`flows/cockpit.pen`), engine gated on a 4-filter card.

- Reuse as-is: `Trading::Domain::PortfolioSummary`, `PeriodReturnsCalculator#chart_data`,
  `Portfolio#allocation_by_asset_type` / `#allocation_by_sector`, daily `portfolio_snapshots`.
- Benchmark data needs **no new gateway**: `MarketData::Gateways::BanxicoGateway#fetch_auctions`
  already returns CETES rates per term (`CETES_SERIES`).
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
- ⬜ **Left undone: the TopBar bell still has no destination.** `/notifications` exists and the
  redesigned shell links to nothing. It lands with the shell revamp, not from a helper fix.

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
