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
| PriceChart tokens (axis, band fill, RSI line) | From 0.1.0, still open — the chart component may need its own color roles. Tokenize, don't hardcode. |
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
