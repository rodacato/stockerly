# Fidelity audit — how far the code is from the design

> Measured 2026-08-25 against the export batch of the same day, after slice 7 merged.
> Re-measured 2026-08-26 after the D31/D34/D35 deletions — five view directories are gone, and
> **no screen without an artboard is still drifting**: each was drawn, deleted, or kept with a date.
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

> 🐞 **The first pass of this table counted wrong, and the numbers below are the corrected ones.**
> The pattern `slate-` matches inside `translate-`, so transform utilities were being counted as
> pre-2.0 palette. Quantified on master before fixing: **13 of 1510 matches, 0.86%** — small enough
> that every conclusion held, large enough that some rows were off by one or two. The counts use
> `\b(slate|gray)-` now. Re-measured 2026-08-26.
>
> **The unit is a matching line, not a match.** `grep -rcE` over the directory, summed. Stated
> because the two differ by roughly 2× — `market` reads 159 by line and 322 by occurrence — and a
> later pass counting the other way would read a regression that is not there. Re-measured after
> the D31/D34/D35 deletions on 2026-08-26.

| View dir | slate | tokens | i18n | | Has an artboard? |
|---|---:|---:|---:|---|---|
| `onboarding` | 0 | 39 | 26 | ✅ 2.0 | yes |
| `setup` | 0 | 2 | 12 | ✅ 2.0 | yes |
| `sessions` | 0 | 2 | 10 | ✅ 2.0 | yes |
| `password_resets` | 0 | 14 | 20 | ✅ 2.0 | yes |
| `assets` | 0 | 34 | 39 | ✅ 2.0 | yes |
| `settings` | 0 | 33 | 22 | ◐ mixed | yes |
| `portfolios` | 0 | 16 | 23 | ◐ mixed | yes |
| `dashboard` | 4 | 21 | 19 | ◐ mixed | yes |
| `trades` | 26 | 71 | 16 | ◐ mixed | yes |
| `profiles` | 0 | 64 | 0 | ◐ mixed | no |
| `components` | 27 | 30 | 13 | ◐ mixed | the kit |
| `welcome` / `help` | 0 | 2 | 0 | ◐ no i18n | yes / no |
| `alerts` | 0 | 49 | 36 | ✅ 2.0 | yes — closed 2026-08-25 |
| `notifications` | 0 | 9 | 11 | ✅ 2.0 | yes — closed 2026-08-25 |
| `admin/logs` | 0 | 24 | 14 | ✅ 2.0 | yes — closed 2026-08-26 |
| `admin/integrations` | 0 | 27 | 26 | ✅ 2.0 | yes — closed 2026-08-26 |
| `admin/settings` | 0 | 17 | 18 | ✅ 2.0 | yes — closed 2026-08-26 |
| `market` | 0 | 175 | 83 | ✅ 2.0 | yes — closed 2026-08-26 |
| `positions` | 33 | 1 | 1 | ✗ pre-2.0 | no — kept, reviewed at #294 (D35) |
| `shared` | 32 | 12 | 0 | ✗ pre-2.0 | mixed |
| ~~`admin/dashboard`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D34) |
| ~~`admin/assets`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D34) |
| ~~`earnings`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D31) |
| ~~`news`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D31) |
| ~~`search`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D35) |

**When this was first measured, exactly one directory was 2.0 by every measure: `onboarding`.**
Reglas and the Bandeja joined it on 2026-08-25; the rest is still mixed or pre-2.0.

The last column is what separates a defect from a decision. A pre-2.0 directory **with** an
artboard is unfinished work. One **without** is either a screen the redesign deliberately left
routable and unlisted (§6b) or one nobody has drawn yet — and migrating an undrawn screen means
inventing design, which is why `admin/dashboard` and `admin/assets` stay open in #289 rather than
riding along with the three that had artboards.

**Corrected 2026-08-26:** the first pass credited those two with artboards. They have none — the
`ajustes-*` set covers the hub, Integraciones, Registros and Estado, and nothing else. **Both were
then deleted rather than drawn** (D34): every card they carried already had a 2.0 home, and the two
capabilities that did not — the manual source triggers, and adding/removing an asset — moved to
Estado and Rastreados. The five struck-through rows are kept in the table on purpose: a row that
vanishes reads as a screen that was migrated.

## Flow by flow

### Auth — ✅ faithful

Four screens on tokens and i18n, sharing `_auth_header` and `_auth_field` so they cannot drift.
`auth-2fa.png` stays an artboard on purpose (D23).

### Onboarding — ✅ faithful

Slice 7. The only directory that is 2.0 on all three measures.

### Activos — ✅ faithful, one neighbour behind

`assets` is clean. `trades` is mixed at 26 slate: the sheet at `/trades/new` was redesigned, the
older `_trade_form` / `_trade_row` / `_edit_row` around it were not.

### Cockpit — ✅ faithful, depth included

Panorama, Consolidado and the asset detail's two tabs all match. What does not: the partials the
asset detail renders *below* those tabs, which no slice touched.

**Closed 2026-08-26.** `market/` is at zero on all three measures. What follows is the state that
produced #294, kept because the partial table is still the map of what the detail renders:

| Partial | slate | Reachable from |
|---|---:|---|
| `_fixed_income_detail` | 39 | asset detail, a CETES asset |
| `_earnings_tab` | 24 | asset detail |
| `_dividend_history` | 17 | asset detail |
| `_metric_card` | 16 | asset detail |
| `_statement_table` / `_statements_tab` | 20 | asset detail |
| `_analyst_target` | 10 | asset detail |

**Every one hung off a screen that is designed** — `_listings_table` and `_filters` went with the
listing (D31). Opening a CETES asset used to show a 2.0 header over a 2019 body; the two heaviest
partials were rewritten rather than tokenised, `_summary_tab` and `_category_tab` were deleted when
the scroll absorbed them, and `Señales` is the one block the data cannot support ([#306](https://github.com/rodacato/stockerly/issues/306)).

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

### Ajustes — ✅ every screen behind the hub, now that two of them were deleted instead

`/settings` is close to 1:1. Deltas: the `Tema` label is missing, the code adds a **Guardar** button
the artboard has none of (it implies auto-save), and the *Trabajos* badge is absent — which §8
explains, a cross-database count aborted the request transaction.

**Registros, Estado and Integraciones closed 2026-08-26**, all three at zero. §8 named this and
left it: *"the four instance screens keep their admin styling. Folding those into the hub's visual
language is a further pass."* **That pass had artboards §8 did not have** — `ajustes-integraciones`,
`ajustes-registros`, `ajustes-estado`.

**`admin/dashboard` and `admin/assets` had none, and were deleted rather than drawn** (D34). Estado
gained one section it was not drawn with: the manual source triggers, kept because a failed source
otherwise has no way back before its next scheduled run. That is the audit's own rule applied —
when the artboard draws less than the screen does, keep the capability and write it down.

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

**Corrected 2026-08-27 — the design half of that price was already paid.** Read from the kit
rather than assumed: `kit-version` is **0.6.0**, `BottomNav` and `SidebarNav` both carry five
destinations with `Descubrir` at index 3 on lucide `compass`, and `AppShellDesktop` instances
`SidebarNav` by `ref`, so it inherited them without an edit. The flows re-vendored and the
exports were re-shot in the same pass — `cockpit-panorama-default`, `reglas-confluencia` and
`ui-kit-shell-desktop` all draw five tabs. **Only the code is outstanding**, which is the
opposite of what this section said and the reason it is corrected rather than deleted: the
paragraph above sent a reader to redo design work that was done.

---

# TODO

Grouped as Adrian framed it. Ordered within each group by what unblocks the most.

## Migrate — a screen exists, its artboard exists, they do not match

1. ✅ **Reglas (`/alerts`)** — done 2026-08-25. Table → cards, inline form → `+ Nueva` sheet (D14),
   *Últimos disparos* wired to the inbox, channels reusing Ajustes' real switches, 64 slate → 0,
   0 → 36 i18n keys. Two conditions that were built and never offered
   (`price_crosses_below`, `day_change_percent`) are reachable now. The `browser_push` toggle is
   the one piece that could not ship — see item 9.
2. ✅ **Bandeja (`/notifications`)** — done 2026-08-25. Four typed filters, date grouping, a tint
   per type, *Borrar las leídas* rendered at last, renamed to *Bandeja*.
3. ✅ **The four instance screens** — [#289](https://github.com/rodacato/stockerly/issues/289)
   closed 2026-08-26. Registros, Estado and Integraciones migrated; `admin/dashboard` and
   `admin/assets` were **deleted instead of drawn** (D34), because every card they carried already
   had a 2.0 home. The manual source triggers moved to Estado and asset add/remove to Rastreados —
   the two capabilities that had nowhere else to go.
4. ✅ **`admin/assets`** — deleted with the above. `toggle_status` turned out to be the same action
   as `assets#toggle_sync`, already on Rastreados.
5. ✅ **The asset-detail depth** → [#294](https://github.com/rodacato/stockerly/issues/294).
   Done 2026-08-26. `market/` went 159 slate → 0 and 1 i18n key → 83; the sub-tabs flattened into
   the artboard's scroll with the glossary's tail behind one control; Contexto de mercado and the
   confluence semaphore are built. Two bugs were found by screenshotting it and fixed with it —
   six of the ten Resumen cards rendered "—" on data that had arrived, and every percentage was
   100× too small. **`Señales` and `Más análisis` could not be built** → [#306](https://github.com/rodacato/stockerly/issues/306):
   `TechnicalObservation` stores events, not state, and nothing persists today's RSI. See D37.

   The original scoping line, kept because it explains what was decided before the work started:
   Scoped 2026-08-26 to the **Análisis tab only**, with four decisions taken: the sub-tabs flatten
   into the artboard's scroll with *"Ver todos los fundamentales"* opening an accordion in place;
   the confluence semaphore ships lights 1 and 3 real and light 2 as *próximamente*; the 36-metric
   glossary moves to i18n and interpretive chips are built **only where a threshold can be written
   and defended**; Mi posición splits off to [#301](https://github.com/rodacato/stockerly/issues/301).
   **`considera vender` is dropped from the artboard** — ADR-0001 forbids buy/sell advice, and
   *"Estirado — no es momento de comprar"* is descriptive without crossing that line.
6. ⬜ **Mi posición's two gaps** → [#301](https://github.com/rodacato/stockerly/issues/301) —
   the `Rendimiento` block (no per-window return series exists) and `Cerrar posición` (a write
   flow, not a restyle). Discovery deliberately incomplete: no documented trigger yet.

## Complete — designed, no code

6. ⬜ **`/discover`** → [#291](https://github.com/rodacato/stockerly/issues/291)
7. ⬜ **§9 Alpaca** → [#290](https://github.com/rodacato/stockerly/issues/290)
8. ⬜ **The fifth nav destination** → [#292](https://github.com/rodacato/stockerly/issues/292)

## Support — the design asks for something the code cannot do

0. ⬜ **Domain-layer copy reaching the UI in English** → [#302](https://github.com/rodacato/stockerly/issues/302).
   Found twice the same day in unrelated places, which is what makes it a pattern:
   `DataSourceRegistry`'s thirteen source names render raw on Estado, and `MetricDefinitions`'
   36 metrics × 3 fields do the same on the asset detail. The second half is inside #294; the
   first is deferred. The decision is not *whether* to translate but where the boundary sits —
   a provider name (`Polygon.io`) is a proper noun, a capability label (`Market Indices`) is UI
   copy that happens to live in code.

9. ⬜ **`browser_push`** → [#293](https://github.com/rodacato/stockerly/issues/293). Reglas shipped
   two toggles rather than three; the design and the code disagree in writing until this is called.
10. ⬜ **Fifteen basket ETFs** absent from the catalogue. Rides #290.
11. ⬜ **The *Trabajos* badge** — needs a way to count failed jobs without a cross-database query in
    the hub's request path. Rides #289.
12. ⬜ **The *Olas* exposure chip** (*"ya vía NVDA"* / *"sin exposición"*) — a Trading read from
    inside Descubrir. ADR-002 allows it through the public read API; it needs one. Rides #291.

## Clean — dead or misleading, found while measuring

13. **Retire the "DONE" convention in `CODE_CHANGES.md`,** or qualify it. Nine sections say shipped
    while five directories with artboards are pre-2.0. This is the defect that produced the whole
    audit: the record was accurate and still misled.
14. **The design README's `done · in review`** should say what is done — the `.pen`, not the ERB.
15. **`docs/pivot-self-hosted-tracker`** — 112 commits behind, its content already on master by
    another route. So is `design/discover` (5 commits, its remote gone). Both are Adrian's to
    delete.
16. **`welcome` / `help`** — on tokens, zero i18n keys, and they share `_welcome_body`.

## Change — a decision to revisit, not a bug

17. **The *Guardar* button in Ajustes** — the artboard implies auto-save. Pick one.
18. ✅ **`/positions`, `/earnings`, `/search`, `/news`** — [#295](https://github.com/rodacato/stockerly/issues/295)
    closed 2026-08-26 (D35). `/earnings`, `/news` and `/market`'s listing deleted per D31;
    `/search` deleted. `GlobalSearch` was kept alongside it *"for the TopBar search the artboards draw"* — **checked 2026-08-27 and the artboards draw none**: `ui-kit-shell-desktop` and every mobile TopBar are brand plus bell. The one search the design does draw is Rastreados·Buscar, served by `assets#search_ticker`. The use case was deleted. **`/positions`
    kept, with a date**: it is reached from the asset detail, it is the only home for global trades
    and dividends, and its review is #294 — if it has no artboard when that closes, it goes then.

    **The framing was wrong and measuring fixed it.** The issue read four equally-adrift screens;
    only `/search` was actually orphaned. `/market`'s listing had six inbound links, two of them
    from screens already closed against their artboards, so deleting it meant *choosing a
    destination* (Activos) rather than removing dead code.
