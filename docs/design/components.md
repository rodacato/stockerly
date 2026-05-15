# Stockerly Component Catalog

> Quick reference for the UI building blocks. Token values: [`tokens.md`](./tokens.md). Brand reasoning: [`brand.md`](./brand.md). **The implemented ERB partial is the source of truth** for built components — this catalog lists purpose, variants, and tokens, then links to the file.

---

## 1. Status

12 components in the original spec (S2 #34). 9 built (S3–S6); 3 deferred. Implementation lives under `app/views/components/`. Variants on top of built components have grown beyond the spec list — see column "Implementation" for the actual partial.

| # | Name | Purpose | Implementation | Status |
|---|---|---|---|---|
| 1 | Button | Trigger an action; 4 variants for hierarchy. | inline (no partial — `button_tag` / `button_to`) | ✓ built |
| 2 | Card | Container for grouped content. | inline (no partial — rounded `<section>` / `<div>`) | ✓ built |
| 3 | KpiCard | Headline number + delta. | [`_kpi_card.html.erb`](../../app/views/components/_kpi_card.html.erb) | ✓ built |
| 4 | Badge | Inline tag for state / currency / category. | [`_status_badge.html.erb`](../../app/views/components/_status_badge.html.erb), [`_log_severity_badge.html.erb`](../../app/views/components/_log_severity_badge.html.erb), [`_data_status.html.erb`](../../app/views/components/_data_status.html.erb) | ✓ built (3 variants) |
| 5 | DataTable | Dense rows of records. | inline (no partial — `<table>` with shared classes) | ✓ built |
| 6 | EmptyState | Honest "nothing here yet" panel. | [`_empty_state.html.erb`](../../app/views/components/_empty_state.html.erb) | ✓ built |
| 7 | Skeleton | Loading placeholder. | [`_skeleton.html.erb`](../../app/views/components/_skeleton.html.erb) | ✓ built |
| 8 | Sparkline | Inline mini-chart in a table cell. | [`_sparkline.html.erb`](../../app/views/components/_sparkline.html.erb) | ✓ built |
| 9 | DonutChart | Compositional breakdown (allocation). | [`_donut_chart.html.erb`](../../app/views/components/_donut_chart.html.erb) | ✓ built |
| 10 | FormField | Label + control + helper + error. | inline (no partial — labels + Rails form helpers) | ✓ built |
| 11 | ThemeToggle | system / light / dark switcher. | (Stimulus controller, not a partial) | planned |
| 12 | DateStamp | Timezone-explicit current moment. | (none) | planned |

Additional partials in `app/views/components/` beyond the original 12: `_asset_badge`, `_asset_price`, `_asset_fundamentals`, `_back_to_top`, `_feature_card`, `_global_search`, `_index_card`, `_integration_card`, `_news_card`, `_notification_panel`, `_market_status_indicator`. These grew organically from S3–S5 and met the §16 promotion bar.

---

## 2. Per-component reference

Each section: variants + tokens. Read the ERB file (or the in-code class strings) for anatomy and exact markup. **If the catalog and the code disagree, the code wins** — open a PR to update this doc.

### 2.1 Button
Variants: `primary` (the single loud action per screen), `secondary` (important non-action), `ghost` (tertiary), `danger` (destructive — confirm before executing).
Tokens: `primary` / `primary-hover` / `fg-inverse` (primary); `bg-surface` + `border-default` (secondary); `fg-default` (ghost); `error` + `fg-inverse` (danger). Plus `radius.md`, `font-body`, weight 600.

### 2.2 Card
A rounded `<div>` or `<section>` with a light border, optional shadow. No standalone partial — apply the class string inline, since variants exist mostly in header/footer composition. Current pattern: `bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm`. *(The `tokens.md` Lumen spec calls for `bg.surface` / `border.default` named tokens; the current `@theme` does not yet expose them — Lumen palette adoption is a separate work item.)*

### 2.3 KpiCard
Headline value (`font-mono font-bold` per `brand.md` §2 numeric rule) + delta pill (success or error tone) + optional subtitle. Built variants: stat-card and admin-kpi-card unified in S03. Tokens: `success`/`error` pair for the delta pill (`bg-X/10 dark:bg-X/20 + text-X-fg dark:text-X` per `tokens.md` §4.1). Card surface uses the inline pattern from §2.2.

### 2.4 Badge
Inline pill. Variants: status (success/error/warning/info), severity (log_severity_badge with 4-tier mapping), currency (USD / MXN), data freshness (data_status). Tokens: `bg-X/10 dark:bg-X/20 + text-X-fg dark:text-X` (per tokens.md §4.1).

### 2.5 DataTable
Native `<table>` with `border-default` dividers, sortable `<th>` (each with `aria-sort`), zebra rows via `hover:bg-bg-muted`, dense padding (`py-2 px-3`). Numeric cells use `font-mono` + `text-right`. Required ARIA: sortable `<th>` carries `aria-sort="ascending|descending|none"` and an inner button with descriptive `aria-label`.

### 2.6 EmptyState
Icon + headline + optional sub + optional CTA. Two variants: actionable (with CTA button) vs neutral (no button when there's nothing to do). Don't render a CTA when the user can't act.

### 2.7 Skeleton
Loading placeholder; matches final layout dimensions to prevent layout shift. Default 5 rows for DataTable loading; never exceed above-the-fold visible row count. Current pattern: `bg-slate-200 dark:bg-slate-700` with `animate-pulse` + `skeleton-shimmer` (the slate neutral track is intentional — placeholders should read as "absence of content", not as semantic state).

### 2.8 Sparkline
Inline 7-day mini-chart in a table cell. SVG polyline; stroke = `success` (up) or `error` (down). Width fixed to fit the cell; no axis labels.

### 2.9 DonutChart
SVG conic-gradient or stroke-segments donut for compositional breakdown. Variants: single-segment (100% one asset → render flat circle with name centered, OR EmptyState — never a solid ring). Scales to 120 px on mobile; legend wraps below.

### 2.10 FormField
Label + input + helper text + error. Two error paths: Rails validation (post-submit) and async `validate` endpoint. Same visual treatment. Tokens: `bg-surface` + `border-default` (idle), `border-error` + `text-error-fg` (error), `border-primary` (focus).

### 2.11 ThemeToggle *(planned)*
Spec: three-state radio group (system / light / dark) with `aria-checked` on the active option. Default to light, not system (closed-beta personal tool, predictable first impression).

### 2.12 DateStamp *(planned)*
Show current time with explicit timezone (e.g., "14:32 CDT"). If client clock and server clock disagree by >2 min, render server time with `(server)` suffix.

---

## 3. Composition patterns

ASCII layout sketches removed — see implemented views instead. Each link shows a canonical layout for that page archetype.

- **Dashboard:** [`app/views/dashboard/show.html.erb`](../../app/views/dashboard/show.html.erb)
- **Portfolio detail:** [`app/views/portfolios/show.html.erb`](../../app/views/portfolios/show.html.erb)
- **Auth pages (login / forgot password / reset):** [`app/views/sessions/new.html.erb`](../../app/views/sessions/new.html.erb), [`app/views/password_resets/new.html.erb`](../../app/views/password_resets/new.html.erb), [`app/views/password_resets/edit.html.erb`](../../app/views/password_resets/edit.html.erb)
- **Market detail (symbol page):** [`app/views/market/show.html.erb`](../../app/views/market/show.html.erb)
- **Trade entry:** [`app/views/trades/_trade_form.html.erb`](../../app/views/trades/_trade_form.html.erb)
- **Alerts index + rule cards:** [`app/views/alerts/index.html.erb`](../../app/views/alerts/index.html.erb) (alert-detail is not yet a dedicated page; rules render inline via [`_alert_rule.html.erb`](../../app/views/alerts/_alert_rule.html.erb))

---

## 4. Don't-build list

Rejected components — adding any later requires a brief justification in [`brand.md`](./brand.md).

- **Tooltip illustrations / mascot characters.** Brand voice is sober.
- **Carousels.** If content has sort order, list it; if not, prioritize the top.
- **Sticky "buy now" CTAs.** No transactional language; no upsell affordance.
- **Achievement / streak badges.** Stockerly tracks portfolios, not engagement.
- **Animated number tickers.** Numbers update on real events, not on render.
- **Success / info toasts, engagement nudges.** These belong inline.

### Toast carve-out
A single `AlertToast` is permitted for **alert-rule trigger events while the user is on a non-Alerts page** — anchored bottom-right, max 1 visible at a time, auto-dismisses after 8 s, click routes to alert detail, persists in the navbar bell badge after dismiss. Rule: toasts never substitute for inline state. Cross-context, time-sensitive events only.

### Deferred (will exist later, not banned)
- **Modal / Dialog.** Implied by Button's `data-confirm`. Placeholder: browser-native `confirm()`. When shipped, must include focus trap, `Esc` to close, return focus to opener.
- **Tabs.** Used informally on Portfolio + Market detail. Until a shared component lands, render as `<nav>` of links with `aria-current="page"` on the active one.
- **Dropdown / Combobox.** Used informally on Trade entry symbol autocomplete. Native `<datalist>` is the placeholder.

---

## 5. When to add a new component

All three must be true:
1. The pattern has appeared in **≥3 screens** during a single sprint.
2. No existing component, with small variants, covers the need.
3. A reviewer (or Renata as sub-agent) confirms no brand-rule violation per [`brand.md`](./brand.md).

The catalog stays small on purpose: shared abstractions get used wrong as they multiply.

---

## 6. When to invoke Renata

Renata Cifuentes is the UX/UI Designer voice in [`docs/research/experts.md`](../research/experts.md). Invoke as a sub-agent when a UI decision is loud enough to be embarrassing to ship without her perspective.

**Invoke before:** adding a new component to this catalog · introducing motion/animation · a redesign touching ≥2 screens · the first beta invite (final accessibility + scan-path audit) · proposing a "but this case needs a toast" exception · adding mobile-specific patterns · a copy change affecting voice consistency across 3+ screens.

**Don't invoke for:** single-component bug fixes · token value tweaks · adding content within an existing component (a new DataTable row, a new Badge variant on established palette) · internal refactors that don't change visual output.

Other experts (Hiroto for architecture, Lucía for financial, Esther for scope/JTBD) at [`docs/research/experts.md`](../research/experts.md).

---

## 7. Renata's preliminary principles (S2 #34)

The full Appendix A (Renata's preliminary UX/UI input) has been compressed. Three pieces remain because they are immutable decisions or unimplemented work-items:

### 7.1 Immutable decisions (don't revisit without strong cause)
- Lumen palette + warm-dark over slate-dark (Saturday-morning use).
- JetBrains Mono on all numbers — non-negotiable.
- ADR-001 (descriptive-not-prescriptive) extends to UI copy.
- Default to light, not system.
- No mascots, no streaks, no neon, one accent color (primary blue), green/red as the only state colors.
- Catalog size ~12. Promote only after 3 screens use the pattern.

### 7.2 Open work-items flagged for the migration
- **AlertToast carve-out** (above): without it, alerts go silent on non-Alerts pages.
- **DataTable → card list on mobile (`<md`):** the table doesn't transform into a card list yet on small screens; rule from Renata is "hard mobile spec, not a hint".
- **KpiCard stale-data + partial-data states:** dim the number + add a `warning` Badge ("Datos atrasados · sync HH:MM"). Don't hide the number — honest defaults.
- **Glyph prefix on gain/loss cells** (`▲` / `▼` / `–` at `font-mono`): accessibility for deuteranopia + better scannability.
- **ThemeToggle as radio group** with `aria-checked` — current implementation is invisible to assistive tech for state.
- **Modal/Dialog** specified or explicitly deferred — `data-confirm` already implies one.

### 7.3 Accessibility contrast notes (status-check at S6 close)
The `-fg` foreground variants documented in [`tokens.md` §4.1](./tokens.md) resolve the original concerns Renata flagged in S2 (saturated `text-success` on `bg-success/10` failing WCAG AA). All migrated views use the `text-X-fg dark:text-X` pattern. Sparkline strokes in dark mode and `fg.subtle` on `bg.canvas` should be re-verified during the beta audit (§6 "first beta invite" trigger).

---

> Last reviewed 2026-05-15 (S06 #68 — initial trim from 821 → ~200 lines per anti-pattern #4 doc bloat). Re-audit when ThemeToggle and DateStamp ship, or when a new component is promoted per §5.
