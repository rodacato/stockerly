# Fidelity audit — how far the code is from the design

> Measured 2026-08-25 against the export batch of the same day, after slice 7 merged.
> Companion to [CODE_CHANGES.md](CODE_CHANGES.md), which tracks execution. This one asks a
> narrower question: **for each flow, does the code look like the artboard?**
>
> Every number is a grep or a screenshot, never an impression.

## Why this document exists

Adrian's read was that design and code still feel distant, and the work order disagreed — nine of
its ten sections say **shipped**. Both are right, and the gap between them is the finding:

**A section says DONE when its slice closed, and a slice closed when its screens shipped — not
when its neighbours did.** §6 "Reglas y avisos — DONE" covers the *code fixes* it names (the
`sms_notifications` rename, `TriggerNotice`, the bell's destination). The Reglas *screen* was never
revamped. Nothing in that line is false; it just does not mean what a reader takes it to mean.

The design README has the mirrored problem: every flow reads **done · in review**, which is true of
the `.pen` file and says nothing about the ERB.

## The measurement

`slate-*`/`gray-*` utilities are the pre-2.0 palette; `bg-bg-*`/`text-fg-*`/`border-border-*` are the
Lumen token contract; `t(...)` is ADR-011. A screen is 2.0 when the first column is zero.

| View dir | slate | tokens | i18n | | Has an artboard? |
|---|---:|---:|---:|---|---|
| `onboarding` | 0 | 39 | 26 | ✅ 2.0 | yes |
| `setup` | 0 | 2 | 12 | ✅ 2.0 | yes |
| `sessions` | 0 | 2 | 10 | ✅ 2.0 | yes |
| `password_resets` | 0 | 14 | 20 | ✅ 2.0 | yes |
| `assets` | 0 | 21 | 26 | ✅ 2.0 | yes |
| `settings` | 1 | 33 | 22 | ◐ mixed | yes |
| `portfolios` | 1 | 16 | 23 | ◐ mixed | yes |
| `dashboard` | 5 | 21 | 19 | ◐ mixed | yes |
| `trades` | 26 | 71 | 16 | ◐ mixed | yes |
| `profiles` | 1 | 64 | 0 | ◐ mixed | no |
| `components` | 27 | 30 | 15 | ◐ mixed | the kit |
| `welcome` / `help` | 0 | 2 | 0 | ◐ no i18n | yes / no |
| **`alerts`** | **64** | 3 | **0** | ✗ pre-2.0 | **yes — 3 artboards** |
| **`notifications`** | **34** | 0 | **0** | ✗ pre-2.0 | **yes — 1 artboard** |
| **`admin/assets`** | 66 | 2 | 0 | ✗ pre-2.0 | **yes** |
| **`admin/logs`** | 55 | 2 | 0 | ✗ pre-2.0 | **yes** |
| **`admin/dashboard`** | 55 | 0 | 0 | ✗ pre-2.0 | **yes** |
| **`admin/integrations`** | 35 | 4 | 0 | ✗ pre-2.0 | **yes** |
| **`admin/settings`** | 34 | 1 | 0 | ✗ pre-2.0 | **yes** |
| `market` | 195 | 71 | 21 | ✗ pre-2.0 | partly |
| `positions` | 33 | 1 | 1 | ✗ pre-2.0 | no |
| `earnings` | 66 | 5 | 0 | ✗ pre-2.0 | no |
| `search` | 31 | 3 | 0 | ✗ pre-2.0 | no |
| `news` | 25 | 5 | 0 | ✗ pre-2.0 | no |
| `shared` | 32 | 12 | 0 | ✗ pre-2.0 | mixed |

**Exactly one directory is fully 2.0 by every measure and was built that way from the start:
`onboarding`.** Everything else is either mixed or pre-2.0.

The last column is what separates a defect from a decision. A pre-2.0 directory **with** an
artboard is unfinished work. One **without** is a screen the redesign deliberately left routable
and unlisted (§6b), and it stays that way until a trigger says otherwise.

## Flow by flow

### Auth — ✅ faithful

Four screens on tokens and i18n, sharing `_auth_header` and `_auth_field` so they cannot drift.
`auth-2fa.png` stays an artboard on purpose (D23).

### Onboarding — ✅ faithful

Slice 7. The only directory that is 2.0 on all three measures.

### Activos — ✅ faithful, one neighbour behind

`assets` is clean. `trades` is mixed at 26 slate: the sheet at `/trades/new` was redesigned, the
older `_trade_form` / `_trade_row` / `_edit_row` around it were not.

### Cockpit — ◐ the screens are faithful, the depth behind them is not

Panorama, Consolidado and the asset detail's two tabs all match. What does not: the partials the
asset detail renders *below* those tabs, which no slice touched.

`market/` holds 195 slate utilities, and they are not spread evenly:

| Partial | slate | Reachable from |
|---|---:|---|
| `_fixed_income_detail` | 39 | asset detail, a CETES asset |
| `_earnings_tab` | 24 | asset detail |
| `_listings_table` | 20 | `/market` listing |
| `_dividend_history` | 17 | asset detail |
| `_metric_card` | 16 | asset detail |
| `_statement_table` / `_statements_tab` | 20 | asset detail |
| `_analyst_target` | 10 | asset detail |

Seven of the nine hang off a screen that **is** designed. Open a CETES asset and the header is 2.0
while the body underneath it is 2019.

### Reglas — ✗ the largest gap in the app

Three artboards (`reglas-lista`, `reglas-vacio`, `reglas-nueva-regla`), 64 slate utilities, zero
i18n keys. Screenshotted side by side, the two screens are not variants of each other:

| | Artboard | Code today |
|---|---|---|
| Creating a rule | `+ Nueva` opens a sheet (D14) | An inline form card, always expanded, above the list |
| The rules | One card each: symbol, kind chip, state pill, plain-language condition, mono provenance line | A **table** — `ACTIVO / TIPO / CONDICIÓN / ÚLTIMO DISPARO` — which **overflows horizontally on a phone**; the last column is cut off mid-word in the capture |
| Filtering | None. One list | `Activas / Pausadas / Todas` tabs |
| Recent triggers | *Últimos disparos*, colour-dotted, linking to the inbox | *Disparadas recientemente*, an empty state |
| Channels | Three toggles | Two rows with `Desactivado` chips, not switches |

The good news is underneath: `alert_rule_kind_label` (§6) already produces the kind chip, and the
seven rule kinds in code match the artboard's seven exactly. **The domain is right; the screen is
the old one.**

⚠ **One genuine conflict, not a gap.** The artboard's first channel is *"Avisos en la app · Campana
y push del navegador"*. That is `browser_push` — the column §7 found had no delivery behind it and
whose plumbing was deleted on 2026-08-25. Either the design drops the toggle, or D16 reopens and
someone builds a push channel. **It cannot ship as drawn.**

### Bandeja — ✗ pre-2.0, but cheaper than it looks

| | Artboard | Code today |
|---|---|---|
| Title | *Bandeja*, with a back arrow | *Notificaciones*, with an eyebrow |
| Filters | Four chips: `Todas · Alertas · Reportes · CETES` | Two rows — type (`Todos/Alertas/Sistema`) and state (`Todos/No leídas/Leídas`) |
| Rows | Date-grouped cards, a typed icon each | One flat list, coloured left border, `NO LEÍDA` in text |
| Footer | *Borrar las leídas* | absent |

🎁 **`Notification` already carries the four types the artboard asks for** — `alert_triggered`,
`earnings_reminder`, `maturity_reminder`, `system`. The screen's own filter collapses them into two
buckets and throws the distinction away. Restoring it is a scope change, not a data change.

### Ajustes — ◐ the hub is faithful, the four screens behind it are not

`/settings` is close to 1:1. Deltas: the `Tema` label is missing, the code adds a **Guardar** button
the artboard has none of (it implies auto-save), and the *Trabajos* badge is absent — which §8
explains, a cross-database count aborted the request transaction.

Behind it, all five `admin/*` directories are pre-2.0 at 34–66 slate each. §8 named this and left it:
*"the four instance screens keep their admin styling. Folding those into the hub's visual language
is a further pass."* **That pass now has artboards it did not have then** — `ajustes-integraciones`,
`ajustes-registros`, `ajustes-estado`.

### Descubrir — ✗ designed, zero code

Three artboards, no route, no controller, no view. D31 defines it and its disposability contract.

Two facts that set its order:

- **Alpaca is a prerequisite** (D31 promotes D19/§9). There are 13 gateways today and none is
  Alpaca; §9 still needs its own 4-filter card.
- **Of the 17-ETF basket, only `SPY` and `ARKK` exist in the catalogue.** Fifteen are new.
- The *Calendario* block is the only one D31 marks as needing no credential. **It can be built
  before Alpaca**, as the walking skeleton that proves the disposability contract — zero tables, one
  job, 24h TTL — before the gateway is paid for.

## The cross-cutting change: a fifth destination

Every artboard in the new batch draws **five** tabs — `Panorama · Activos · Reglas · Descubrir ·
Ajustes`. `NavigationHelper` has four. Until `/discover` exists, **every mobile artboard in the batch
disagrees with every screen in the app**, which is a large part of why the two feel distant even
where a screen is otherwise faithful.

D31 already priced this: it is not an additive bump. `AppShell`, `AppShellDesktop` and `SidebarNav`
all change, forcing kit 0.6.0, a re-vendor across all six flows, and a re-shoot of every export
showing the bar.

---

# TODO

Grouped as Adrian framed it. Ordered within each group by what unblocks the most.

## Migrate — a screen exists, its artboard exists, they do not match

1. **Reglas (`/alerts`)** — the largest single gap. Table → cards, inline form → `+ Nueva` sheet
   (D14), *Últimos disparos* wired to the inbox, channels as toggles, 64 slate → tokens, 0 → n i18n
   keys. Resolve the `browser_push` conflict first; it changes the channel block.
2. **Bandeja (`/notifications`)** — four typed filters (the data is already there), date grouping,
   typed icons, *Borrar las leídas*, rename to *Bandeja*.
3. **The four instance screens** (`admin/integrations`, `admin/logs`, `admin/settings`,
   `admin/dashboard`) — §8's deferred pass, now with artboards.
4. **`admin/assets`** — 66 slate. Half-absorbed already: Rastreados took the list and the budget;
   create, search and delete still live here.
5. **The asset-detail depth** — the seven partials below the tabs, worst first
   (`_fixed_income_detail` at 39).

## Complete — designed, no code

6. **`/discover`** — after Alpaca. Build *Calendario* first: it needs no credential and proves the
   disposability contract cheaply.
7. **§9 Alpaca** — promoted to prerequisite by D31; still needs its own 4-filter card.
8. **The fifth nav destination** — `NavigationHelper`, both shell variants, and the kit 0.6.0
   re-vendor D31 priced.

## Support — the design asks for something the code cannot do

9. **`browser_push`** — drawn as a channel, deleted as plumbing. Decide: drop the toggle, or reopen
   D16 and build push. **Blocks item 1.**
10. **Fifteen basket ETFs** absent from the catalogue. **Blocks item 6.**
11. **The *Trabajos* badge** — needs a way to count failed jobs without a cross-database query in
    the hub's request path.
12. **The *Olas* exposure chip** (*"ya vía NVDA"* / *"sin exposición"*) — a Trading read from inside
    Descubrir. ADR-002 allows it through the public read API; it needs one.

## Clean — dead or misleading, found while measuring

13. **Retire the "DONE" convention in `CODE_CHANGES.md`,** or qualify it. Nine sections say shipped
    while five directories with artboards are pre-2.0. This is the defect that produced the whole
    audit: the record was accurate and still misled.
14. **The design README's `done · in review`** should say what is done — the `.pen`, not the ERB.
15. **`docs/pivot-self-hosted-tracker`** — 112 commits behind, its content already on master by
    another route.
16. **`welcome` / `help`** — on tokens, zero i18n keys, and they share `_welcome_body`.

## Change — a decision to revisit, not a bug

17. **The *Guardar* button in Ajustes** — the artboard implies auto-save. Pick one.
18. **`/positions`, `/earnings`, `/search`, `/news`** — 155 slate utilities across four screens
    with **no artboards**, routable and unlisted since §6b. Either they get designed, or they get
    deleted, or the decision to leave them is written down with a date. Today they are simply
    drifting, which is how the 22 phases started.
