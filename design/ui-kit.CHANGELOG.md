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
