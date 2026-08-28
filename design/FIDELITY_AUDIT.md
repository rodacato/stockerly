# Fidelity audit — how far the code is from the design

> Companion to [CODE_CHANGES.md](CODE_CHANGES.md), which tracks execution. This one asks a
> narrower question: **for each flow, does the code look like the artboard?**
>
> Every number is a grep or a screenshot, never an impression.

## How to read the dates in this document

**Every section carries its own _as of_ line, and the document has no date of its own.** That is
deliberate, and it is a repair.

This header used to advertise three re-measurement dates — 2026-08-25, -26 and -27 — so a reader
took the whole file as current. It was not: on 2026-08-27 three of the seven flow sections had
never been re-read since they were first written, and they were describing screens that had shipped
two days earlier. Reglas was still called *"the largest gap in the app"* on the same page as a
table that scored it 2.0 and a TODO item that marked it done. A document-level date cannot be true
of a document that is revised in pieces — it can only make the stale pieces look fresh.

So: **a section is current as of the date printed under its own heading, and no later.** If you
change what a section describes, re-read the section and move its date. If you cannot re-read it,
leave the old date — an honestly stale section is useful and a falsely fresh one is not.

_Header rewritten 2026-08-27._

## Why this document exists

_As of 2026-08-25 — the diagnosis that opened the audit, kept as written._

Adrian's read was that design and code still feel distant, and the work order disagreed — nine of
its ten sections say **shipped**. Both are right, and the gap between them is the finding:

**A section says DONE when its slice closed, and a slice closed when its screens shipped — not
when its neighbours did.** §6 "Reglas y avisos — DONE" covers the *code fixes* it names (the
`sms_notifications` rename, `TriggerNotice`, the bell's destination). The Reglas *screen* was never
revamped. Nothing in that line is false; it just does not mean what a reader takes it to mean.

The design README has the mirrored problem: every flow reads **done · in review**, which is true of
the `.pen` file and says nothing about the ERB.

## The measurement

_As of 2026-08-27 — every row below re-run on this date, not carried forward._

`slate-*`/`gray-*` utilities are the pre-2.0 palette; `bg-bg-*`/`text-fg-*`/`border-border-*` are the
Lumen token contract; `t(...)` is ADR-011. A screen is 2.0 when the first column is zero.

The three commands, per directory, so the next pass counts the same way:

```sh
grep -rcE '\b(slate|gray)-[0-9]+'          app/views/<dir> | awk -F: '{x+=$NF} END{print x+0}'
grep -rcE 'bg-bg-|text-fg-|border-border-' app/views/<dir> | awk -F: '{x+=$NF} END{print x+0}'
grep -rcE '\bt\('                          app/views/<dir> | awk -F: '{x+=$NF} END{print x+0}'
```

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
| `onboarding` | 0 | 40 | 27 | ✅ 2.0 | yes |
| `setup` | 0 | 2 | 12 | ✅ 2.0 | yes |
| `sessions` | 0 | 2 | 10 | ✅ 2.0 | yes |
| `password_resets` | 0 | 14 | 20 | ✅ 2.0 | yes |
| `assets` | 0 | 35 | 47 | ✅ 2.0 | yes |
| `settings` | 0 | 33 | 22 | ◐ mixed | yes |
| `portfolios` | 0 | 16 | 23 | ◐ mixed | yes |
| `dashboard` | 0 | 20 | 18 | ✅ 2.0 | yes |
| `trades` | 0 | 76 | 16 | ◐ mixed | yes |
| `profiles` | 0 | 64 | 0 | ◐ no i18n | no |
| `components` | 0 | 50 | 12 | ✅ 2.0 | the kit |
| `welcome` / `help` | 0 | 2 + 2 | 0 | ◐ no i18n | yes / no |
| `discover` | 0 | 25 | 17 | ✅ 2.0 | yes — built 2026-08-27 (#291/#292) |
| `alerts` | 0 | 49 | 36 | ✅ 2.0 | yes — closed 2026-08-25 |
| `notifications` | 0 | 9 | 11 | ✅ 2.0 | yes — closed 2026-08-25 |
| `admin/logs` | 0 | 24 | 14 | ✅ 2.0 | yes — closed 2026-08-26 |
| `admin/integrations` | 0 | 24 | 19 | ✅ 2.0 | yes — closed 2026-08-26 |
| `admin/settings` | 0 | 17 | 19 | ✅ 2.0 | yes — closed 2026-08-26 |
| `market` | 0 | 192 | 101 | ✅ 2.0 | yes — closed 2026-08-26 |
| `positions` | 0 | 30 | 1 | ◐ no i18n | yes — drawn 2026-08-27 (D43) |
| `shared` | 0 | 40 | 0 | ◐ no i18n | mixed |
| `layouts` | 0 | 10 | 4 | ✅ 2.0 | the shell |
| ~~`admin/dashboard`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D34) |
| ~~`admin/assets`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D34) |
| ~~`earnings`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D31) |
| ~~`news`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D31) |
| ~~`search`~~ | — | — | — | 🗑 deleted 2026-08-26 | never had one (D35) |

**When this was first measured, exactly one directory was 2.0 by every measure: `onboarding`.**
Reglas and the Bandeja joined it on 2026-08-25.

> **Nine cells were wrong before this re-run, and none of them was wrong when written.** The table
> was presented as re-measured on 2026-08-27 while carrying digits from earlier passes: `discover`
> read 11 tokens / 10 i18n against an actual 25 / 17 (it grew after the row was written), `market`
> 108 i18n against 101, `components` 17 against 12, `portfolios` 27 against 23, `dashboard` 20
> against 18, `alerts` 37 against 36, `assets` 34 / 42 against 35 / 47, `admin/logs` 16 against 14,
> `admin/settings` 18 against 19. **The slate column really was 0 everywhere** — the finding the
> table led with survived its own audit, which is why the wrong digits went unnoticed. Direction of
> travel matters more than any single cell, and it is mixed: i18n keys fall when copy is
> consolidated, not only when it regresses.

**Re-measured 2026-08-27, and the first column is zero everywhere.** The pre-2.0 palette is
gone from `app/views` entirely: `grep -rcE '\b(slate|gray)-[0-9]+' app/views` returns nothing.
123 occurrences went — 28 deleted with the files nobody rendered, 95 migrated to the token
contract. What is left in the third column is i18n, not palette: `profiles`, `shared`, `welcome`
and `positions` carry copy that is still hardcoded es-MX, which ADR-011 permits surface by surface
and this table should stop reading as though it were the same debt as a slate utility.

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

**Each section below is dated.** Take none of them as current past its own date — see *How to read
the dates* at the top.

### Auth — ✅ faithful for what exists, and four artboards now have no code

_As of 2026-08-27, re-measured after the ADR-018 pass._

Four screens on tokens and i18n, sharing `_auth_header` and `_auth_field` so they cannot drift.
The controller's three flashes were **not** on i18n despite §3c claiming the surface had landed —
they are now `auth.flash.*`, which is what the rest of the app does.

**`auth-2fa.png` no longer "stays an artboard on purpose (D23)".** D23 is reversed by
[ADR-018](../docs/architecture/adr/0018-totp-with-recovery-codes.md): TOTP is being built, with
recovery codes in the same scope. So the gap grew from one artboard to **four** — `2FA`,
`TOTP · Alta`, `Códigos de recuperación` and `Código de recuperación` — and it is now a work order
rather than a deliberate hold. Verified by grep: no `otp`, `two_factor` or `2fa` anywhere in `app/`
or `config/routes.rb`. The order lives in [CODE_CHANGES.md](CODE_CHANGES.md) §14.

### Onboarding — ✅ faithful

_As of 2026-08-27._

Slice 7, shipped 2026-08-25 (CODE_CHANGES §9b). This section used to call it *"the only directory
that is 2.0 on all three measures"*; that stopped being true the same week, and it is now one of
many — `assets`, `dashboard`, `discover`, `alerts`, `notifications`, `market` and the three admin
directories all score the same. The claim was a superlative with a short shelf life.

### Activos — ✅ faithful, and its neighbour caught up

_As of 2026-08-27._

`assets` is clean, and so is `trades`.

**Corrected 2026-08-27.** This section read *"`trades` is mixed at 26 slate: the sheet at
`/trades/new` was redesigned, the older `_trade_form` / `_trade_row` / `_edit_row` around it were
not."* Re-measured: `grep -rcE '\b(slate|gray)-[0-9]+' app/views/trades` returns **0** on every
file, and **`_trade_form` does not exist** — `app/views/trades/` holds `index`, `new`,
`_trade_row`, `_edit_row` and `_confirm_delete_row`. Two errors in one sentence: a count that had
been fixed, and a partial named from memory rather than from `ls`.

What is still true and is a different thing: `trades` sits at 16 i18n keys against 76 token uses,
so its copy is largely hardcoded es-MX. ADR-011 permits that surface by surface, so it is a queue
position, not a defect.

### Cockpit — ✅ faithful, depth included

_As of 2026-08-26._

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

### Reglas — ✅ migrated

_As of 2026-08-27._

**Migrated 2026-08-25, and this section spent two days saying the opposite.** It was headed
*"✗ the largest gap in the app"* and led a five-row artboard-vs-code table — on the same page as a
measurement table scoring `alerts` 2.0 and a TODO item marking the same work done. Three
statements about one screen, in one file, disagreeing. It is the clearest instance of the pattern
the last TODO group names, which is why the old table is kept below rather than deleted.

Re-measured: `app/views/alerts/` is **0 slate / 49 tokens / 36 i18n**. Row by row against the
table it used to carry:

| | Artboard | Code, 2026-08-27 |
|---|---|---|
| Creating a rule | `+ Nueva` opens a sheet (D14) | ✅ `alerts/index.html.erb:25-27` renders `components/sheet_dialog` into a `rule_sheet` frame |
| The rules | One card each | ✅ A `<ul id="alert_rules">` of `alerts/_alert_rule` cards. The overflowing table is gone |
| Filtering | None. One list | ✅ |
| Recent triggers | *Últimos disparos*, linking to the inbox | ✅ Wired to the inbox |
| Channels | Toggles | ✅ Renders `settings/notification_switches` — the same real switches Ajustes uses, not chips |
| Copy | — | ✅ Every string is a `t(".key")` lookup |

`alert_rule_kind_label` (§6) produces the kind chip and the seven rule kinds in code match the
artboard's seven — the note this section originally filed as *"the domain is right; the screen is
the old one"*. Only the second half changed.

⚠ **The one thing that did not ship, and it was a genuine conflict rather than a gap.** The
artboard's first channel is *"Avisos en la app · Campana y push del navegador"* — `browser_push`,
the column §7 found had no delivery behind it. It was **dropped** on 2026-08-25 (D16, §7): no
`web-push` gem, no VAPID pair, no subscriptions table, and on iOS the channel can fail silently on
the primary device. The artboard still draws the toggle. **The design is the side that has to move
here**, and it is TODO 11's record.

### Bandeja — ✅ migrated

_As of 2026-08-27._

**Migrated 2026-08-25**, and — like Reglas — described here as *"✗ pre-2.0"* for two days after.
`app/views/notifications/` is **0 slate / 9 tokens / 11 i18n**.

| | Artboard | Code, 2026-08-27 |
|---|---|---|
| Title | *Bandeja*, with a back arrow | ✅ Renamed |
| Filters | Four chips: `Todas · Alertas · Reportes · CETES` | ✅ `notifications/index.html.erb:17-20` renders exactly those four, each with its count |
| Rows | Date-grouped cards, a typed icon each | ✅ |
| Footer | *Borrar las leídas* | ✅ `borrar_leidas` is in `config/locales/es-MX.yml` and rendered |

🎁 The finding that made it cheap held: **`Notification` already carried the four types the
artboard asks for** — `alert_triggered`, `earnings_reminder`, `maturity_reminder`, `system` — and
the old filter collapsed them into two buckets. Restoring the distinction was a scope change, not
a data change, which is why this was the smallest of the three migrations.

### Ajustes — ✅ every screen behind the hub, now that two of them were deleted instead

_As of 2026-08-27._

`/settings` is close to 1:1. Deltas: the `Tema` label is missing, and the code adds a **Guardar**
button the artboard has none of (it implies auto-save).

The *Trabajos* badge is absent, and as of 2026-08-27 that is **settled rather than pending**: the
reason is written into the code at
[`settings/show.html.erb:44-46`](../app/views/settings/show.html.erb#L44-L46) — counting
`SolidQueue::FailedExecution` puts a cross-database query in the hub's request path, which aborted
the transaction outright in test, and Mission Control shows the real number the moment you open it.
The artboard draws a count the screen will not have. That is a design change, not open work.

**Registros, Estado and Integraciones closed 2026-08-26**, all three at zero. §8 named this and
left it: *"the four instance screens keep their admin styling. Folding those into the hub's visual
language is a further pass."* **That pass had artboards §8 did not have** — `ajustes-integraciones`,
`ajustes-registros`, `ajustes-estado`.

**`admin/dashboard` and `admin/assets` had none, and were deleted rather than drawn** (D34). Estado
gained one section it was not drawn with: the manual source triggers, kept because a failed source
otherwise has no way back before its next scheduled run. That is the audit's own rule applied —
when the artboard draws less than the screen does, keep the capability and write it down.

### Descubrir — ✅ built, at three blocks

_As of 2026-08-27._

**Shipped 2026-08-27 (#291/#292).** `/discover` exists and proved the disposability contract: zero
tables, one route, two YAMLs, one job, and a spec that pins the absence of a migration.

This section described it as **◐ half-built, waiting on Alpaca**, and every clause of that has
since moved. Corrected against the tree rather than the artboard:

- **Three blocks ship: Olas · Titulares · Calendario.** Both Alpaca-dependent blocks are live —
  `show.html.erb:30` renders the ranked baskets and `:78` the five headlines. **#290 is closed**, so
  nothing here waits on a gateway.
- **Reportes is gone, and not because it was unbuilt.** D47 **dropped it from the product and from
  the artboards** on 2026-08-27: Alpaca serves `historical`, `news`, `dividends` and `splits` and
  never earnings, so the block would have put a third provider on the screen for the weakest of the
  four. It returns only with its own 4-filter card. A reader of the old text would have gone looking
  for work that was cancelled.
- **The 17-symbol basket ships in full**, as `config/discover_baskets.yml` — 16 baskets plus the
  `SPY` baseline. The old *"only SPY and ARKK exist in the catalogue"* measured the wrong thing:
  D31 clause 5 says a basket has **no `Asset`** by contract, so the `Asset` catalogue was never the
  place to look.
- ⚠ **`WarmDiscoverJob` is not absent.** This section said it and its `recurring.yml` entry were
  *"absent on purpose: with no Alpaca there is nothing to warm"*. Both exist:
  `app/jobs/warm_discover_job.rb`, scheduled `every 4 hours` at `config/recurring.yml:59-61`, with
  the 24 h TTL so a failed run serves stale waves rather than an empty screen.
- **The Calendario is real but half-loaded**, and that part still holds. The Fed's 2026 dates are
  in; Banxico publishes its own as a non-machine-readable PDF (D33), so the rest is hand-entered
  and the block declares the year it covers. D33's exhausted state was **answered**, not left open:
  the view renders a `calendario_agotado` string when the file runs out.

## The cross-cutting change: a fifth destination

_As of 2026-08-27 — closed. Kept as the record of how it was priced, mis-recorded and paid._

Every artboard in the new batch draws **five** tabs — `Panorama · Activos · Reglas · Descubrir ·
Ajustes`. `NavigationHelper` has four. Until `/discover` exists, **every mobile artboard in the batch
disagrees with every screen in the app**, which is a large part of why the two feel distant even
where a screen is otherwise faithful.

D31 already priced this: it is not an additive bump. `AppShell`, `AppShellDesktop` and `SidebarNav`
all change, forcing kit 0.6.0, a re-vendor across all six flows, and a re-shoot of every export
showing the bar.

**Corrected 2026-08-27 — the design half of that price was already paid.** Read from the kit
rather than assumed: **0.6.0** put five destinations into `BottomNav` and `SidebarNav` with
`Descubrir` at index 3 on lucide `compass`, and `AppShellDesktop` instances `SidebarNav` by `ref`,
so it inherited them without an edit. The flows re-vendored and the exports were re-shot in the
same pass — `cockpit-panorama-default`, `reglas-confluencia` and
`ui-kit-shell-desktop` all draw five tabs. **Only the code is outstanding**, which is the
opposite of what this section said and the reason it is corrected rather than deleted: the
paragraph above sent a reader to redo design work that was done.

**Closed 2026-08-27 (#292/#334).** `NavigationHelper` carries five destinations, `/discover`
exists, and the specs that pinned four were updated rather than deleted. This section stops being
the cross-cutting gap and stays only as the record of how it was priced, mis-recorded, and paid.

**And it was mis-recorded twice.** The paragraph above wrote *"`kit-version` is 0.6.0"* **inside
the paragraph correcting that very number** — a fix that shipped with the same defect it was
fixing. The kit went to **0.7.0** the same day (the new mark, D45), re-syncing all seven flows.
The version reference is removed above rather than re-pinned: this document has no business
mirroring a number `ui-kit.CHANGELOG.md` owns, because mirroring is how it went stale both times.

---

# TODO

_As of 2026-08-27._

Grouped as Adrian framed it. Ordered within each group by what unblocks the most.

> **Renumbered 2026-08-27.** The list had **two items numbered 6** (Mi posición and `/discover`),
> a Support group that started at **0** and then jumped to 9, and a Clean group that skipped 17-18
> because those numbers were in use one group below. Items are now numbered **1–22 in reading
> order**, and the one internal cross-reference was repointed. Old numbers are noted in
> parentheses where an item moved, so a link from elsewhere can still be resolved.

## Migrate — a screen exists, its artboard exists, they do not match

1. ✅ **Reglas (`/alerts`)** — done 2026-08-25. Table → cards, inline form → `+ Nueva` sheet (D14),
   *Últimos disparos* wired to the inbox, channels reusing Ajustes' real switches, 64 slate → 0,
   0 → 36 i18n keys. Two conditions that were built and never offered
   (`price_crosses_below`, `day_change_percent`) are reachable now. The `browser_push` toggle is
   the one piece that could not ship — see item 11.
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

**This group is empty of open work as of 2026-08-27.** All three closed within a day of each
other, and the group is kept because its items are what the sections above cite.

7. ✅ **`/discover`** *(was the second item 6)* → [#291](https://github.com/rodacato/stockerly/issues/291).
   Built 2026-08-27 and **no longer in its sin-datos state**: Olas and Titulares read Alpaca and
   are live, the Calendario is live, and **Reportes was dropped from the product** (D47) rather
   than left waiting. This item read *"the Alpaca notice and the Calendario are live; Olas,
   Reportes and Titulares wait on the gateway"* — of that sentence, one clause survives and it is
   the Calendario.
8. ✅ **§9 Alpaca** *(was 7)* → [#290](https://github.com/rodacato/stockerly/issues/290) closed.
   The gateway is at `market_data/gateways/alpaca_gateway.rb`, registered as `:alpaca_us` in
   `config/initializers/data_sources.rb`, and six jobs call it. CODE_CHANGES §9 still read
   "pending" on 2026-08-27 and was corrected there.
9. ✅ **The fifth nav destination** *(was 8)* → [#292](https://github.com/rodacato/stockerly/issues/292)
   closed 2026-08-27. Five destinations, `/discover` routed, the four-entry specs updated.

## Support — the design asks for something the code cannot do

10. ✅ **Domain-layer copy reaching the UI in English** *(was 0)* → [#302](https://github.com/rodacato/stockerly/issues/302)
    closed 2026-08-27. `MetricDefinitions` went with #294; the registry's labels moved to
    `data_sources.<key>` in the locale, and the boundary the issue asked for is written into the
    registry itself — a provider proper noun reads the same in any locale, a capability label is
    copy.
11. ✅ **`browser_push`** *(was 9)* → [#293](https://github.com/rodacato/stockerly/issues/293)
    closed. The column was **dropped** (D16, CODE_CHANGES §7), so the open item is on the design
    side: `reglas-lista` still draws a bell toggle the product does not have.
12. ✅ **Fifteen basket ETFs** *(was 10)* — **closed 2026-08-27, and the item was measuring the
    wrong thing.** It read *"absent from the catalogue, rides #290"*. The basket does not live in
    the `Asset` catalogue and by D31 clause 5 never can — a basket has no `Asset` by contract. It
    lives in `config/discover_baskets.yml`, which ships all 16 baskets plus the `SPY` baseline,
    exactly the 17 symbols D31 settled. Nothing was absent; the question was.
13. ✅ **The *Trabajos* badge** *(was 11)* — **decided, not pending.** It rode #289, which item 3
    records as closed on 2026-08-26. The decision is written into the code at
    [`settings/show.html.erb:44-46`](../app/views/settings/show.html.erb#L44-L46): no badge,
    because counting `SolidQueue::FailedExecution` puts a cross-database query in the hub's request
    path, and Mission Control shows the number accurately on open. **What is left is an artboard
    that draws a count** — a design change, filed with item 11's.
14. ✅ **The *Olas* exposure chip** *(was 12)* (*"ya vía NVDA"* / *"sin exposición"*) — built.
    `app/helpers/discover_helper.rb:5` is `wave_exposure`, called from
    `discover/show.html.erb:50`. The read API ADR-002 required exists; both states render neutrally
    on purpose, since colouring *"sin exposición"* would say *act here*.

## Clean — dead or misleading, found while measuring

15. **Retire the "DONE" convention in `CODE_CHANGES.md`,** or qualify it *(was 13)*. Nine sections say shipped
    while five directories with artboards are pre-2.0. This is the defect that produced the whole
    audit: the record was accurate and still misled.

    **Reinforced 2026-08-27, three times in one day, and the pattern is sharper than "DONE".** The
    record is written when a decision is taken and never revisited when reality moves: this file
    said the kit still had four destinations after it had been bumped to five and re-vendored;
    two flow briefs still read `kit-version-source 0.5.0` while their own `BottomNav` carried
    Descubrir; and `GlobalSearch` was kept for a TopBar search the artboards do not draw. None was
    wrong when written. **What is missing is not a better verb — it is a habit of re-reading the
    record against the thing it describes**, which is what this section is for and why each of
    those was corrected in place rather than deleted.

    **Extended 2026-08-27, and the sweep this note asked for was finally run.** Reading this
    document against the tree turned up **eleven** more of the same kind, in this file and its
    four neighbours: `CODE_CHANGES` §9 and §10 both said "pending" about shipped work, §6b counted
    four nav destinations against five, §8 still ran on a D18 that ADR-015 reversed, `§10` was used
    twice as a section number, `ui-kit.CHANGELOG` 0.7.0 said the kit led code that had shipped,
    `COMPONENT_INVENTORY` listed three partials that do not exist and crossed 13 kit components
    against a kit of 18, and this file's Reglas, Bandeja and Descubrir sections described screens
    that had migrated days earlier. **The structural fix adopted instead of a better verb: every
    section carries its own _as of_ date** (see the top of this file). A document-level date is
    what let three unread sections pass as current.
16. **The design README's `done · in review`** should say what is done — the `.pen`, not the ERB
    *(was 14)*. Partly addressed 2026-08-27: the README now warns above the table and each row that
    has landed says so, but the status column still reads the `.pen`'s state.
17. **`docs/pivot-self-hosted-tracker`** *(was 15)* — 112 commits behind, its content already on
    master by another route. So is `design/discover` (5 commits, its remote gone). Both are
    Adrian's to delete.
18. **`welcome` / `help`** *(was 16)* — on tokens, zero i18n keys, and they share `_welcome_body`.
    Still true 2026-08-27: 2 token uses each, 0 keys.
19. **The Confluencia artboard is out of date.** `reglas-confluencia` still carries the notice *"El
    semáforo está diseñado, no construido"*, and lights 1 and 3 were built in #294 as readings. It
    also describes a mechanism that does not exist: nothing combines the three lights inside a
    window, and there is no confluence window in code at all. **Building that screen as drawn would
    describe a mechanism the instance does not have** — the D13/D16/D23/D25 pattern. Fix the
    artboard before anyone builds from it.
20. ✅ **"Watchlist" and "Sigo" are the same tier under two names** — **the vocabulary call was
    taken 2026-08-27 (D48), and it went to Watchlist.** `watchlist_items.flash.*` said *"Agregado a
    tu watchlist"* while the Activos artboard labelled the tier **Sigo** (D9); the ladder now reads
    **Holdings · Watchlist · Tracked** across product and design, and the observation sense of
    *movimiento* becomes **Señales**, leaving *movimiento* to mean a trade. The code, the copy and
    the artboard names migrate as their own change — this item is closed as a decision, not as
    shipped work.

    ⚠ **One collision D48 creates, worth naming before someone builds into it:** *Señales* is
    already the name of the asset-detail block item 5 could not build (#306, no persisted current
    RSI). After D48 the same word also names the Panorama's observations block. Two screens, one
    word, both about observations — resolvable, but not by accident.

## Change — a decision to revisit, not a bug

21. **The *Guardar* button in Ajustes** *(was 17)* — the artboard implies auto-save. Pick one.
22. ✅ **`/positions`, `/earnings`, `/search`, `/news`** *(was 18)* — [#295](https://github.com/rodacato/stockerly/issues/295)
    closed 2026-08-26 (D35). `/earnings`, `/news` and `/market`'s listing deleted per D31;
    `/search` deleted. `GlobalSearch` was kept alongside it *"for the TopBar search the artboards draw"* — **checked 2026-08-27 and the artboards draw none**: `ui-kit-shell-desktop` and every mobile TopBar are brand plus bell. The one search the design does draw is Rastreados·Buscar, served by `assets#search_ticker`. The use case was deleted. **`/positions`
    kept, with a date**: it is reached from the asset detail, it is the only home for global trades
    and dividends, and its review is #294 — if it has no artboard when that closes, it goes then.
    **That date came due**: #294 closed 2026-08-26 with no artboard, and rather than delete the
    route, `[Activos] / Historial / Default` was drawn 2026-08-27 (D43). Measuring decided it —
    one inbound link from outside the screen, three of its four tabs with none, and three lists
    with no other home. The "posiciones abiertas" tab was dropped: it duplicated Cartera, which is
    the likeliest reason nobody ever linked to the screen.

    **The framing was wrong and measuring fixed it.** The issue read four equally-adrift screens;
    only `/search` was actually orphaned. `/market`'s listing had six inbound links, two of them
    from screens already closed against their artboards, so deleting it meant *choosing a
    destination* (Activos) rather than removing dead code.
