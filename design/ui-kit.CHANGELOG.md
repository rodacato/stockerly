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

> `cockpit.pen` stays on `0.1.0` with its own local copies of the five. That is legal (being
> behind is fine; diverging is not) — re-vendor it when it is next opened for edits.

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

**Vendored by:** `flows/assets.pen` (kit-version-source `0.3.0`) — its five inline copies were
replaced with instances in the same pass.

### Gaps to watch (candidates for 0.4.0)

| Need | Note |
|---|---|
| `WatchRow` | `flows/assets.pen` local. `AssetRow`'s skeleton but carries price + Δ día + "sigues +X%". One flow — promote only if a second needs it. |
| `TierChip` (Poseo / Sigo) | `flows/assets.pen` local, 2 artboards, 1 flow. Wait for `alerts.pen`. |
| `OptionCard` (icon + title + desc + chevron) | Empty-state paths and the Rastreados entry row in `assets.pen`. `onboarding.pen` looks like it has the same shape — **verify against it before promoting**, it was not open during this pass. |
| `TopBarBack` (back + title + action) | Two artboards in `assets.pen`; `cockpit.pen`'s asset-detail bar is close but stacks ticker + name. Similar, not identical — do not force one master over both. |
| PriceChart tokens (axis, band fill, RSI line) | From 0.1.0, still open — the chart component may need its own color roles. Tokenize, don't hardcode. |
| Semáforo "live vs próximamente" states | From 0.1.0, still open — needs a distinct treatment, not color alone (D3). |
