# Code changes — landing the redesign in code

> The WORK ORDER for landing design-side decisions in code. A `Dn` entry in
> [DECISIONS.md](DECISIONS.md) records the finding + decision; this doc tracks its **execution**.
> Because this is a redesign, the kit leads the code — each section flips the kit from "ahead of
> code" to "1:1 mirror" once it ships.

**Rule: consolidation/adoption decisions cite MEASURED usage, not impressions.** Lead each section
with grep counts.

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
