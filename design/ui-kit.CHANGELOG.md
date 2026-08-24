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

### Gaps to watch (candidates for 0.3.0)

| Need | Note |
|---|---|
| `scrim` color token | Bottom-sheet overlay. Tokenized flow-locally in `flows/assets.pen` (`#0F172A99` light / `#000000B3` dark) — promote once a second flow needs a modal. |
| `WatchRow` | `flows/assets.pen` local. Same skeleton as `AssetRow` but carries price + Δ día + "sigues +X%". Promote only if a second flow needs it; otherwise it stays a feature-local row. |
| `Segmented` (2-tab pill) | Rebuilt inline in 4 artboards of `assets.pen` and again in `cockpit.pen`'s asset detail toggle. Cheapest real promotion of the next batch. |
| `OptionCard` (icon + title + desc + chevron) | Empty-state paths in `assets.pen`; onboarding has a near-identical shape. Compare the two before promoting. |
