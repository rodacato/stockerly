# ui-kit.lib.pen — Changelog

Pencil can't reference components across `.pen` files, so each `flows/*.pen` **vendors** the kit
at a pinned version via the install script — it does NOT link live. Bumping here means flows on an
older version may need a re-sync.

**Version markers:** `kit-version` variable lives in `ui-kit.lib.pen`; each flow records the
version it vendored in `kit-version-source`.

**Bump rules:** patch = token value tweak · minor = new/changed token or component ·
major = breaking rename/removal. Additive bumps don't force re-syncs. A changed token VALUE forces
every consumer.

---

## Open kit gaps

**Live list, not history** — each entry is a gap a flow worked around, kept here so the next bump
has its candidates in one place instead of scattered across the entries that found them. A gap
leaves this list by shipping or by being declined on the record.

| Gap | Found | Where it lives meanwhile |
|---|---|---|
| **`NavRow` has no recommended/primary state** | 0.8.0, vendoring into `assets.pen` — three copies had drifted and snapped back, a fourth carried a deliberate `$primary` accent because it is the recommended path out of an empty portfolio | An instance override in `assets.pen`. A second consumer earns the variant |
| **No detail `TopBar`** | 0.8.0, `cockpit.pen` — the kit ships the root bar (`Brand`/`Bell`) only | `TopBarDetail` local to `cockpit.pen`: two-line ticker title plus a bookmark. **Measured against `HeaderBar` and they are different components**, so 0.9.0 did not absorb it. Its `Bookmark` slot is asset-specific and would come off in a kit version |
| **`TopBar` has no count badge** | 0.8.1, `alerts.pen` — the kit ships `UnreadDot`, an 8px dot | A numbered badge local to `alerts.pen`, which is the flow that owns the inbox: a count says more than a dot. If a second flow wants the number, the variant is earned |
| **No `focus` token** | #489, 2026-09-04 — the app's most common focus ring (18 inputs) had no kit name | Shipped in the code contract as `--color-focus` (`#5B6CFF33` / `#7B89FF33`), D76. The kit has not taken it: rule 2 makes every kit change a manual re-vendor across ten consumers, so it is promoted when a `.pen` needs it. **19 consumers as of #561**, and the newest is not a focus ring: the metric card's open-state ring takes the same value, because it marks the control the reader just activated. If a `.pen` ever promotes this, weigh `ring-accent` as the name — the row was left as `focus` in #561 rather than renamed one PR after it landed (D77) |
| **No `transparent` token** | The consistency sweep, 2026-08-27 | `cockpit.pen` carries 44 `#00000000` literals — transparency, not colour. `README.md` says *"tokens only — zero hex in a flow"*, and the kit gives no way to spell "no fill", so **the rule currently forbids its own only spelling**. Either a token or a sentence in the rule |


**The version lives in the `kit-version` variable inside `ui-kit.lib.pen`** — that is the only
place it is true. This file deliberately no longer restates it: a mirrored number went stale three
times (this line said 0.8.0 while the kit was at 0.9.0; the canvas label said 0.5.0 and 0.8.0 while
the variable said 0.7.0 and 0.9.0). Entries below are historical and are not rewritten when a later
version supersedes them — **read the newest entry that mentions a component, not the first**, and
keep them in ascending order so "newest" means "last".

> **Vocabulary, renamed 2026-08-27 (D48).** The tier ladder moved to the industry-standard English
> names: **Poseo → Holdings · Sigo → Watchlist · Rastreado(s) → Tracked**. The observation sense of
> *movimiento* is now **Señales**; *movimiento* alone means a trade. Older entries below still carry
> the pre-D48 names because they record what was true when written — `TierChip (Poseo / Sigo)` in
> the 0.4.0 gap list is the ladder D48 renames. The `.pen` masters and the ERB copy migrate
> separately; this note exists so the old names are not read as current.

---

## 0.1.0 — initial

**Tokens (37):** the `@theme` contract from `app/assets/tailwind/application.css` — semantic roles
`primary / bg-{canvas,surface,muted} / fg-{default,subtle,inverse} / border-{default,strong} /
positive/negative/warning/info (+bg/+fg)`, light + dark. **Values = the code's Lumen palette**
(cheerful indigo `#5B6CFF`) per D1 — design and code converge on color. Fonts: display **Plus Jakarta
Sans**, body Inter, mono JetBrains Mono. Radii 8/12/16/20 (D1). Green/red reserved for gain/loss.

**Components (5):** ButtonPrimary, ButtonSecondary, Field, Card, Stepper — the shared primitives.
Flow-specific components (Semaforo, AssetRow, PriceChart, MetricRow…) arrive with their flows and
get promoted here when shared across ≥2 flows (Adrian's growth model).

**Vendored by:** `flows/onboarding.pen`, `flows/auth.pen` (kit-version-source `0.1.0`).

### Gaps to watch (candidates for 0.2.0)

| Need | Note |
|---|---|
| Categorical palette (allocation slices) | The Consolidado donut needed four non-semantic category colors and the kit has none — green/red are reserved for gain/loss, so it borrowed `primary`, `primary-hover`, `warning` and `fg-subtle`. `warning` on a crypto slice reads as a caution it does not mean. A real 4–6 colour categorical ramp is the fix. |
| PriceChart tokens (axis, band fill, RSI line) | new chart component may need its own color roles — tokenize, don't hardcode |
| Semáforo "live vs próximamente" states | needs a distinct token/treatment, not color alone |

---

## 0.2.0 — cockpit components promoted (minor)

Batch promotion requested by Adrian after `cockpit.pen` settled. Additive only — no token
values changed, so **no consumer is forced to re-sync**.

**Components (+5, now 10):** `TopBar`, `BottomNav`, `AssetRow`, `MovementItem`, `MarketCard`.

| Promoted | From | Why it earned the kit |
|---|---|---|
| `TopBar` | `cockpit.pen` (raw, duplicated per screen) | App shell — every authenticated screen in every flow repaints it. Was never a component; 3 hand-copies already existed. |
| `BottomNav` | `cockpit.pen` (raw, duplicated per screen) | Same, plus D4 names the nav as *the* component with mobile/desktop variants. Active tab = per-instance override on the tab's icon + label. |
| `AssetRow` | `cockpit.pen` `AssetRow2` (10 instances) | The canonical asset row (ticker/name · value/PnL · sparkline · state chip · semáforo dots). Consumed by `assets.pen` (Cartera + Sigo) — the ≥2-flow bar, cleared. |
| `MovementItem` | `cockpit.pen` (6 instances) | Icon + asset + reason + tag. Reused for trade log rows (`assets.pen`) and rule-trigger rows (`alerts.pen`). |
| `MarketCard` | `cockpit.pen` (9 instances) | Label + big value + chip + 3-segment gauge. Generic enough for the "vs CETES / vs sólo mantener" comparison cards on the consolidado screen. |

**Not promoted (measured, 0 instances — dead in `cockpit.pen`):** `AssetRow` (the older one,
superseded by `AssetRow2`) and `AttentionItem` (the "atención hoy" band ended up built from
`MovementItem`). Recommend deleting both from `cockpit.pen` on its next touch — flagged, not done.

**Vendored by:** `flows/assets.pen` (kit-version-source `0.2.0`).

> `cockpit.pen` stayed on `0.1.0` at the time with its own local copies of the five; it was
> re-vendored to `0.3.0` on 2026-08-24, when its `AssetRow2` was renamed `AssetRow` to match the kit
> and the two dead components were deleted.

---

## 0.3.0 — Segmented + scrim (minor)

Additive; no token values changed, so no consumer is forced to re-sync.

**Component (+1, now 11):** `Segmented` — the two-tab pill.
**Token (+1, now 38):** `scrim` — modal/sheet overlay (`#0F172A99` light, `#000000B3` dark).

Measured before promoting: **7 hand-built copies across 2 flows** — 5 in `flows/assets.pen`
(Cartera/Sigo on four artboards + Compra/Venta in the trade sheet) and 2 in `cockpit.pen`
(the Análisis / Mi posición toggle on both asset-detail artboards). Active state is a
per-instance override on the two segments; labels likewise. `cockpit.pen`'s compact variant
overrides `padding` and drops `fill_container` — same master, different sizing.

The `scrim` was tokenized flow-locally in `assets.pen` when the trade sheet needed it; promoted
now so the next flow with a modal (alerts rule create) cannot invent a second alpha.

**Vendored by:** `flows/assets.pen` and `flows/cockpit.pen` (kit-version-source `0.3.0`) — all seven
inline copies were replaced with instances in the same pass.

---

## 0.4.0 — NavRow + SwitchRow (minor)

Additive; no token values changed.

**Components (+2, now 13):** `NavRow`, `SwitchRow`.

Measured before promoting, both across two flows:

| Promoted | Count | Where |
|---|---|---|
| `NavRow` (icon + title/desc + optional meta + chevron) | **10** | 6 instances in `flows/settings.pen`; 4 hand-built in `flows/assets.pen` — the Rastreados entry and the three paths of the empty state |
| `SwitchRow` (label + description + toggle) | **8** | 5 instances in `flows/settings.pen`; 3 hand-built in `flows/alerts.pen` ("Cómo te aviso") |

The forward reason, beyond tidiness: the ERB translation is next, and these ten sites become **one
partial** in `app/views/components/` instead of three different markups.

**Vendored by:** `flows/settings.pen` (kit-version-source `0.3.0`, its local copies are the same
shape). `alerts.pen` and `assets.pen` keep hand-built copies — legal (behind, not diverging);
re-vendor each when it is next opened for edits.

### Gaps to watch (candidates for 0.5.0)

| Need | Note |
|---|---|
| `PatrimonioStrip` | `flows/cockpit.pen` local, 3 instances, 1 flow. Now that `NavRow` is promoted, check whether this is just a `NavRow` variant before promoting a second row component. |
| `WatchRow` | `flows/assets.pen` local. `AssetRow`'s skeleton but carries price + Δ día + "sigues +X%". One flow — promote only if a second needs it. |
| `ProviderCard` | `flows/settings.pen` local, 6 instances, 1 flow. Name + status dot + quota bar + key count. Nothing else needs a quota bar yet. |
| `LogRow` | `flows/settings.pen` local, 6 instances, 1 flow. |
| `TierChip` (Poseo / Sigo) | `flows/assets.pen` local, 2 artboards, 1 flow. Wait for `alerts.pen`. |
| ~~`OptionCard`~~ | **Resolved into `NavRow` in 0.4.0** — it was the same shape. Still worth checking `onboarding.pen` for a third consumer when that file is next open. |
| `TopBarBack` (back + title + action) | Two artboards in `assets.pen`; `cockpit.pen`'s asset-detail bar is close but stacks ticker + name. Similar, not identical — do not force one master over both. |
| Categorical palette (allocation slices) | The Consolidado donut needed four non-semantic category colors and the kit has none — green/red are reserved for gain/loss, so it borrowed `primary`, `primary-hover`, `warning` and `fg-subtle`. `warning` on a crypto slice reads as a caution it does not mean. A real 4–6 colour categorical ramp is the fix. |
| ~~PriceChart tokens (axis, band fill, RSI line)~~ | **Closed 2026-09-06 — reuse, do not tokenize (D96).** 0.9.0 deferred this on a condition it wrote down: *"no band and no RSI series are drawn yet — when they are, they are a decision, not a backfill."* D96 drew them, and the decision is that they need no roles of their own. The artboard paints the RSI line `fg-default`, the Bollinger bands `border-strong` and the new ATR levels `fg-subtle` at low opacity — three tokens that already exist and already read in both themes. A `chart-rsi` token would ship with exactly one consumer. |
| Semáforo "live vs próximamente" states | From 0.1.0, still open — needs a distinct treatment, not color alone (D3). |

---

## 0.5.0 — the desktop shell (minor)

Additive; no token values changed, so no consumer is forced to re-sync.

**Components (+3, now 16):** `SidebarNav`, `TopBarDesktop`, `AppShellDesktop`.

D4 names the shell as the one component with two variants, and until now only the mobile one
existed — the six flows are 22 mobile artboards and zero desktop. Adrian asked for the desktop
pass across every flow before the shell slice is written in code, so the variant lands in the
kit first and the flows instance it.

| Component | Shape | Replaces on desktop |
|---|---|---|
| `SidebarNav` | 240 wide, brand + the same four destinations stacked, active row on `primary-muted` | `BottomNav` |
| `TopBarDesktop` | screen title + context line on the left, bell on the right | `TopBar` |
| `AppShellDesktop` | 1280×800 frame composing both, with a slot for the screen body | — |

The four destinations, their icons and their labels are copied from `BottomNav`, not
re-picked: the desktop variant is the same navigation in a different geometry. `SidebarNav`
vendors the `Brand` group from `TopBar` rather than redrawing the glyph.

**Why a third component rather than two:** every desktop artboard needs the same frame around
its body, and drawing it per screen is how 22 near-copies drift. `AppShellDesktop` is that
frame; a flow overrides the title, the active destination and the body.

**Vendored by:** nothing yet — the flows re-vendor as each gets its desktop pass.

### Gaps to watch (candidates for 0.6.0)

| Need | Note |
|---|---|
| Master-detail body | D4 calls out cockpit/asset-detail as genuinely divergent. The split lives inside the shell's slot; whether it earns a component depends on how many screens use it. |
| Desktop `Segmented` width | The mobile pill is `fill_container` at 342. On a 1040 body it stretches to something no one wants; a max width or a left-aligned variant is needed. |
| Bell destination | The bell is drawn in both TopBar variants and still points nowhere (D14). |

## 0.6.0 — the fifth destination (minor)

**NOT additive — every consumer that draws the shell must re-sync.** `BottomNav` and `SidebarNav`
changed shape, from four destinations to five, and the flows instance them. This is the re-vendor
D31 priced in advance; it buys nothing for the screens it touches, it only keeps them from lying.

**Components (0 new, still 16):** `BottomNav` and `SidebarNav` each gain **Descubrir** (lucide
`compass`), inserted at **index 3**. `AppShellDesktop` inherits it for free — it instances
`SidebarNav` by `ref` rather than carrying its own copy, so the desktop shell needed no edit.

**Why index 3 and not the end.** Panorama / Activos / Reglas keep the position the thumb already
knows; only Ajustes shifts. On a 390 viewport five items at the bar's current sizing occupy ~320 of
the 374 available, so nothing shrinks — but that is arithmetic, not evidence. Verify on a real
phone (CODE_CHANGES §10.2).

**Consumers to re-sync:** `cockpit`, `assets`, `alerts`, `settings`, `discover`. `auth` and
`onboarding` draw no shell, so they stay on 0.5.0 **behind but not diverging** — the state this
file's own rules declare acceptable.

Decided in D31.

---

## 0.7.0 — the new mark (minor, partly breaking)

**NOT additive for the brand — every consumer that draws the logo must re-sync.** The symbol
changed from the four-bracket focal frame plus dot to a **counterform disc with two carved
candles**. Nothing about the palette or the type moved; D1 still holds. Decided in D45.

**Why the old one had to go.** Four separated strokes at 15.6% inset and 6/64 weight have no mass:
below 24px the brackets lose continuity and the centre dot closes, so the favicon and every
small-chrome instance rendered a smudge. Measured across a size ladder, not eyeballed. The
counterform inverts the failure — a stroke thins as it shrinks, a void does not.

**Components (2 new, 18 total):** `Logo` (horizontal lockup, symbol 44 + wordmark 32, gap 7) and
`LogoMark` (symbol alone, 64). Both additive; nothing is forced to adopt them.

**Changed in place — three copies of the glyph, not one.** `TopBar` › `Brand` › `Glyph`,
`SidebarNav` › `Brand` › `Glyph`, and `Foundations` › `Brand` › `Lockup` › `Glyph`. Each had five
nodes (4 stroke paths + 1 ellipse) replaced by a single `evenodd` path. Brand gap 8 → 4, which is
the lockup rule (separation = 1/6 of the symbol) applied at chrome scale.

**Optical alignment of the wordmark (the fix Adrian caught).** Centring the symbol on the text's
*box* is wrong: the box includes the descender of the "y", so the word hangs low. Measured at
fontSize 32 the word's ink runs 9.4 → 42 inside a 44-tall lockup — 9.4px of air above, 2px below.
The rule is now **shift the wordmark up by 0.115 × fontSize**, implemented as a `WMWrap` frame with
bottom padding of `0.231 × fontSize`. Applied to all four lockups (the three above plus the new
`Logo`). It scales, so any future size gets it for free.

**Two corrections while in there.** The 0.5.0 entry claims `SidebarNav` "vendors the `Brand` group
from `TopBar` rather than redrawing the glyph" — **it does not**. It carries its own `Glyph` and its
own `WM`. And every `Brand` group painted raw hex (`#5B6CFF`, `#0F172A`) instead of `$primary` /
`$fg-default`, against this kit's own tokens-only rule. Fixed.

**Consumers re-synced — all seven, audited rather than assumed.** 23 glyphs and 21 lockups
replaced: `auth` 5/5 and `onboarding` 6/4 (both were on **0.1.0**, six versions back from
before this work), `cockpit` 5/5, `assets` 2/2, `alerts` 1/1, `settings` 2/2, `discover` 2/2.
Every file is on 0.7.0.

**Two hazards the audit found, worth knowing before the next sweep.** A `.pen` must be **open**
for a path to reach it — otherwise the path is silently ignored and the operation lands in a
different open file, with no error. And **node ids are shared across flow files**, because flows
were created by duplicating their neighbour: two files returning the same id is normal, and an
id is never proof of which file you are in. Verify by artboard name before writing.

**`_playground.pen` was not audited** — it was not open during the sweep, so whether it still
draws the old glyph is unknown. It is the one file this bump did not reach. ~~*Answered in 0.8.0:
it draws nothing.*~~

The code-side change (the SVGs under `app/assets/images/` and `public/`, the manifest, the cache
bust) is tracked separately in CODE_CHANGES.md §11.

**Shipped 2026-08-27 — the kit is no longer ahead here.** Verified on disk rather than assumed:
`app/assets/images/logo_light.svg` and `logo_dark.svg`, `public/favicon.svg`, `icon.svg`,
`icon-192.svg`, `icon-512.svg`, `icon-maskable-512.svg` and their PNG rasters, plus
`app/views/shared/_logo_mark.html.erb` — the `LogoMark` this version added. The sentence this
paragraph replaced said the kit led the code, and it stopped being true the day §11 landed.


---

## 0.8.0 — the six logged gaps, three of which were not gaps

Every gap this kit had accumulated since 0.1.0, worked in one batch so the seven flows re-vendor
once instead of six times. **Three of the six needed no work at all** — the code had already
answered them, which is the finding worth keeping.

### Tokens (+14, 38 → 52) — mirrored, not designed

`chart-1` … `chart-8` plus `chart-neutral`, and the Fear & Greed scale `sentiment-1` … `sentiment-5`,
light and dark, lifted verbatim from `app/assets/tailwind/application.css`.

The gap list called this "a 4–6 colour categorical ramp for the Consolidado donut", as though it
were a design task. It was not: the code ships a closed eight-colour ramp in an `@theme static`
block and `components/_donut_chart.html.erb` already renders its conic-gradient from it. The kit
was simply behind. **The `sentiment` scale was in neither the gap list nor any ledger** — found by
reading the file the ramp lives in.

The donut complaint that motivated the gap ("`warning` on a crypto slice reads as a caution it does
not mean") describes the artboards, not the app. The code stopped borrowing semantic colours when
the ramp landed.

### Two gaps closed by evidence

**`PriceChart` tokens (axis, band fill, RSI line) — not needed.** Open since 0.1.0.
`app/javascript/controllers/chart_controller.js` reads `--color-fg-subtle` for axis text,
`--color-border-default` for grid lines and scale borders, and `--color-chart-1` for the series.
The chart is built, it is on `lightweight-charts` per D2, and it needs nothing this kit lacks. Band
fill and an RSI line have no tokens because no band and no RSI series are drawn yet — when they
are, they are a decision, not a backfill.

**Semáforo `live` vs `próximamente` — not a token, and not a kit component.** `market/_confluence.html.erb`
renders a pending light as a `bg-muted` dot with `opacity-60` on its row (D36 ships light 2 that
way). Both are already available — one existing token and a node property. The semáforo is drawn
flow-locally and is not in this kit, so there was nothing here to add. Recorded so flows stop
inventing a treatment that is already settled.

### TopBar · TopBarDesktop — the unread badge, and the touch target nobody noticed

`BellWrap` on both bars: a 44×44 target, the bell centred, and an 8px `negative` dot inset 10px
from the top-right. Mirrored from `components/_notification_badge.html.erb`, whose badge sits at
`right-2.5 top-2.5 size-2` inside a `size-11` link. Offsets derived from those numbers, not placed
by eye. **It is a dot, not a count** — the number exists only in the screen-reader text.

**The badge was the logged gap; the touch target was the real defect.** The bell was a bare 20×20
icon, so the kit had been failing its own 44pt accessibility floor since 0.5.0 while the code met
it. Fixing it is what makes this bump expensive:

> ⚠️ **TopBar grows 57 → 76** (`py-4` + `size-11`, which is what the code always measured).
> **TopBarDesktop grows 78 → 80.** Every artboard that vendored the mobile bar moves its content
> down 19px. This is additive in the changelog's sense — nothing renamed, nothing removed — but it
> is not free, and it is the reason the kit went first in this pass.

### Segmented3 (+1 component, 18 → 19)

Three equal segments in the same pill. **The code has one N-ary component**, not a family:
`components/_segmented.html.erb` takes an `options` array and gives each entry `flex-1`. Pencil
instances cannot add children, so the kit needs a master per arity — a limitation of the tool, not
a claim about the code. Recorded on the component itself so nobody mirrors the wrong thing back.

### Segmented keeps its own width — D49

The master was pinned at `width: 342`, a number derived from the phone (390 minus 2×24) and
matching neither the code (fills its parent) nor the desktop pass's own rule (*a control is not a
container*). Resolved as **the design rule wins**: the control keeps its width and aligns left on
desktop rather than stretching a 1040 column. The width is unchanged, but it is now a stated
constraint on the component instead of an accident, and the code revamp is tracked in
CODE_CHANGES.md.

### Corrections found while in here

**The canvas label read `COMPONENTES · v0.5.0` while `kit-version` said `0.7.0`** — two minors
stale. The label is what a designer reads on opening the file; the variable is what the install
script pins. They now agree, and the label is part of the bump.

**`_playground.pen` is empty**, settled by reading it: one 800×600 frame, **zero variables, zero
components**. It is not "behind on 0.6.0" and it cannot be drawing the retired mark — it has never
had the kit installed at all. The 0.7.0 entry's open question is answered, and the work it implies
is an install, not a re-vendor.

**Consumers: `flows/assets.pen` re-synced 2026-08-27**, the first onto this version. The remaining
six are still on 0.7.0 and must re-vendor for the TopBar height and the new tokens — flow by flow.

### Gap found while re-vendoring — for the next bump

**`NavRow` has no recommended/primary state.** Vendoring it into `assets.pen` turned up four
hand-built copies, and measuring them before replacing changed what the job was. Three had drifted
about 6% larger (36px icon wrap, 18px icon, padding 14/16, description at 12) and snapped back to
the kit's numbers — that part is the whole point of vendoring. But the fourth, *Captura lo que ya
tienes*, carried a deliberate accent: `$primary` stroke at 1.5, a `$primary-muted` wrap and a
`$primary` icon, because it is the recommended path out of an empty portfolio. Replacing all four
with the plain row would have flattened a real hierarchy while calling it consistency.

It ships as an instance override, not a new variant — the method says do not promote unasked. If a
second flow needs the same accent, that override has earned a variant and this is the entry that
says so.

---

## 0.8.1 — accent text on a muted surface (patch)

**No components added or renamed. One token value moves, one component treatment changes, and the
consumers re-vendor.** Raised by D41's own trigger firing, and found by measuring rather than by eye.

### The rule

> **Accent *text* on a muted surface uses `primary-hover`, never `primary`. Accent *icons* keep
> `primary`.**

Text owes 4.5:1 and `primary` on `primary-muted` does not reach it in either theme — **3.68:1 light**
(`#5B6CFF` on `#EEF0FF`) and **4.24:1 dark** (`#7B89FF` on `#2A2E55`). `primary-hover` does, in both:
**4.96:1** and **5.01:1**. Icons owe 3:1 under non-text contrast, which 3.68:1 already clears, so they
do not move — that is what keeps this a text rule instead of a palette change.

**No background moves**, so surface separation is untouched: `primary-muted` on `bg-canvas` stays at
1.32:1 in dark. And `primary-hover` already existed in the kit and in `application.css`, so the rule
costs zero new tokens.

### Token

**`info-fg` dark `#7B89FF` → `#9098FF`.** In dark the `info` pair was token-identical to the
`primary` pair the rule just rejected — the same 4.24:1 failure under a different name, on the token
whose entire job is being readable on `info-bg`. Light was already fine at 4.96:1 and does not move.

### Component

`SidebarNav`'s active item: its label and its icon were both `$primary` on `$primary-muted`. The
label is `$primary-hover` now; the icon moved too, because it sits inside the same pill as the label
and splitting them read as a defect rather than a rule.

### Why this is a patch and not a minor

Nothing is added, renamed or removed, and no consumer's layout moves — the change is a colour on
existing text. Re-vendoring is a token update plus a fill swap, not a re-layout.

### Consumers re-vendored 2026-08-27

| File | Text nodes moved |
|---|---|
| `flows/assets.pen` | **16** — filter chips, the FX notes, the `Seguir` CTAs, five `Holdings` chips, the nav |
| `flows/cockpit.pen` | **9** — the period segments, `VS. TU PLAN`, `1.3× prom.`, the nav |
| `flows/discover.pen` | **2** — the nav, and the `Ir a Integraciones →` link D41 measured and left |
| `flows/auth.pen` · `_playground.pen` | 0 — neither uses the pair; token updated for parity |

`flows/settings.pen`, `flows/alerts.pen` and `flows/onboarding.pen` are still on 0.7.0 and pick this
up when they migrate.

### What this says about D41

D41 resolved one card and wrote *"no other screen uses `primary-muted` that way today. Worth a look
if a second one wants to."* Measured: **27 text nodes across three flows and six call sites in the
ERB** — the nav, `/trades`' three filter chips, the profile identity badge and the Tracked row's
button. The trigger had already fired when the sentence was written. Recorded as **D56**.

---

## 0.9.0 — HeaderBar (minor)

**+1 component, 19 → 20.** Nothing renamed, nothing removed.

### HeaderBar — the back-header two flows had already built five times

`flows/settings.pen` hand-built it **four** times (Integraciones, Registros, Estado y mantenimiento,
Integraciones · Estados) and `flows/alerts.pen` **twice** (Bandeja, Confluencia). The 0.8.0 gap note
set the bar explicitly — *"if any of them needs the same bar, that is the second consumer and the
promotion is earned"* — and it fired.

**Measured before promoting**, because the same note nearly caused a false match. This is **not**
cockpit's `TopBarDetail`: that one carries a two-line ticker title and a bookmark; this one an 18px
display title and an optional action. Different components, and `TopBarDetail` stays local to
`cockpit.pen` until it finds a second consumer of its own.

| Slot | |
|---|---|
| `BackWrap` | 44×44, `$radius-md` — every hand-built copy had a bare 20px icon |
| `T` | `fill_container`, 18px/700 `$font-display` |
| `Accion` | `fit_content` × 44, icon + label. Icon-only consumers disable the label and pin the wrap to 44 — Pencil instances cannot add children, so the master carries both and instances subtract |

Height 68 at rest, 44 of it the touch target.

### Consumers

`flows/settings.pen` (4 instances) and `flows/alerts.pen` (1 master replaced by the kit's shape).
`cockpit.pen` is untouched — its detail bar is a different component.

---

## 1.0.0 — `AssetRow` loses its state chip and its confluence dots

The first major, and it is a removal rather than an arrival. The bump rule at the top of this file
decides the number on its own: *major = breaking rename/removal*.

### What came out

`AssetRow`'s `Sig` slot — an `Estado` chip reading *oportunidad* and three `Dots`. It was in the
kit and in both flows that vendor the component (`cockpit.pen`, `assets.pen`), and
`app/views/components/_asset_row.html.erb` had said for months that the code backed neither:

> *No state chip and no confluence dots: the design draws both, the code backs neither.*

### Why now, and why removal rather than a build

[#586](https://github.com/rodacato/stockerly/issues/586) retired the semáforo the dots belonged to
(D84): re-measured on ten years, combining the lights beat nothing, and light 1 mechanically implies
light 3's test — 483 episodes, none above the 50-day mean. The chip was then its own question, and
D85 declined it: the edge that would justify it is measured inside a basket returning roughly twice
the index before any signal.

So the slot is not deferred pending a build. There is no build.

### What this does NOT do

**It does not re-vendor the flows.** One component was corrected in all three files so nothing
diverges, but `cockpit.pen` and `assets.pen` keep their `kit-version-source` at `0.8.1` — no full
token-and-component sync happened, and claiming one in the variable is how six briefs came to
contradict their own files (D53).

### Consumers

`cockpit.pen` (Panorama radar, Holdings summary) and `assets.pen` (Holdings, Watchlist). Both
corrected in the same pass.
