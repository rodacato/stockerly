# Stockerly Component Catalog

> The building blocks that compose every Stockerly screen. Token values referenced here live in [`tokens.md`](./tokens.md); the brand reasoning lives in [`brand.md`](./brand.md).

This catalog is the spec, not the implementation. Component code will be added under `app/views/shared/` during the visual migration in Sprints S3–S6. The purpose of this file is to make sure every new screen reaches for the same set of pieces.

---

## 1. Component list

| # | Name | One-line purpose |
|---|---|---|
| 1 | [Button](#2-button) | Trigger an action. Three variants for hierarchy. |
| 2 | [Card](#3-card) | Container for grouped content on the canvas. |
| 3 | [KpiCard](#4-kpicard) | Specialized card for a single headline number + delta. |
| 4 | [Badge](#5-badge) | Inline tag carrying a state, currency, or category. |
| 5 | [DataTable](#6-datatable) | Dense, sortable, color-coded rows of records. |
| 6 | [EmptyState](#7-emptystate) | Honest "nothing here yet" panel. |
| 7 | [Skeleton](#8-skeleton) | Loading placeholder matching final layout. |
| 8 | [Sparkline](#9-sparkline) | Inline mini-chart in a table cell. |
| 9 | [DonutChart](#10-donutchart) | Compositional breakdown (sector, geography, asset type). |
| 10 | [FormField](#11-formfield) | Label + control + helper text + error. |
| 11 | [ThemeToggle](#12-themetoggle) | Three-state: system / light / dark. |
| 12 | [DateStamp](#13-datestamp) | Timezone-explicit current moment shown at the top of pages. |

Each section below follows the same shape: purpose, anatomy, variants, tokens used, and an example markup sketch.

---

## 2. Button

### Purpose
Trigger a single action. Hierarchy controls how loud the button feels.

### Variants

| Variant | When |
|---|---|
| `primary` | The single most important action on the screen (e.g., "Registrar movimiento"). At most one per screen. |
| `secondary` | Important actions that are not THE action ("Cancelar", "Exportar CSV"). |
| `ghost` | Tertiary actions ("Ver más", "Filtros") — looks like a link with button affordance. |
| `danger` | Destructive only ("Eliminar posición"). Triggers a confirm dialog before executing. |

### Sizes

`sm` (28 px height), `md` (36 px, default), `lg` (44 px, used on auth pages).

### Tokens used

- `color.primary` / `color.primary.hover` / `color.fg.inverse` — primary variant fill + text.
- `color.bg.surface` + `color.border.default` — secondary variant.
- `color.fg.default` — ghost variant text.
- `color.negative` + `color.fg.inverse` — danger variant.
- `radius.md`, `font.sans`, weight 600.

### Markup sketch

```erb
<%# Primary %>
<%= button_tag "Registrar movimiento",
      class: "bg-primary hover:bg-primary-hover text-fg-inverse font-semibold px-4 py-2 rounded-md" %>

<%# Secondary %>
<%= button_tag "Exportar CSV",
      class: "bg-bg-surface border border-border-default hover:bg-bg-muted text-fg-default font-semibold px-4 py-2 rounded-md" %>

<%# Ghost %>
<%= button_tag "Ver más",
      class: "text-fg-default hover:bg-bg-muted font-semibold px-3 py-1.5 rounded-md" %>

<%# Danger %>
<%= button_tag "Eliminar posición",
      class: "bg-negative hover:opacity-90 text-fg-inverse font-semibold px-4 py-2 rounded-md",
      data: { confirm: "Eliminar esta posición de forma permanente." } %>
```

### States

- `:hover` — primary/danger darken via `*-hover` token, secondary/ghost shift to `bg-bg-muted`.
- `:focus` — visible focus ring using `color.primary` with 2 px outline; never remove the focus outline for sighted-keyboard users.
- `:disabled` — opacity 50 %, `cursor-not-allowed`, no hover state.
- Loading — replace label with a spinner; preserve button width to prevent layout shift.

---

## 3. Card

### Purpose
Group content that belongs together on the canvas. Provides surface separation and a hit target.

### Anatomy

- Background `color.bg.surface`
- Border `color.border.default` (1 px)
- Radius `radius.lg`
- Shadow `shadow.sm` in light, none in dark (the border carries separation in dark mode)
- Padding `p-6` for default; `p-4` for compact lists; `p-8` for marketing/landing-style hero (rare)

### Markup sketch

```erb
<div class="bg-bg-surface border border-border-default rounded-lg p-6 shadow-sm dark:shadow-none">
  <h3 class="font-display font-semibold text-fg-default">Posiciones abiertas</h3>
  <p class="text-fg-subtle text-sm mt-1">5 of 14, sorted by weight</p>
  <%# ... %>
</div>
```

### Variants

- **Default** — most common, paired with section headings.
- **Compact** (`p-4`) — for dense lists where the card frame should disappear visually.
- **Highlighted** — adds `border-strong` and `bg-primary-muted` background. Use sparingly: empty-state CTA, single onboarding step.

---

## 4. KpiCard

### Purpose
Specialized card showcasing one headline number, an optional delta indicator, and a sub-label. The 4-card row at the top of the dashboard is the canonical use.

### Anatomy

- Layout: Card with `p-6`, vertical rhythm
- Top: small caption label (`text-xs uppercase tracking-wider text-fg-subtle`) — e.g., "PORTFOLIO VALUE"
- Middle: the number (`font-mono text-3xl font-bold text-fg-default`)
- Right of number: delta chip (positive / negative variant of Badge)
- Bottom: sub-label (`text-xs text-fg-subtle`) — e.g., "today, all-currencies"

### Tokens used

- Card tokens (see §3).
- `color.positive` / `color.negative` for delta chips.
- `font.mono` for the number.
- `color.fg.subtle` for both caption and sub-label.

### Markup sketch

```erb
<div class="bg-bg-surface border border-border-default rounded-lg p-6 shadow-sm dark:shadow-none">
  <p class="text-xs uppercase tracking-wider text-fg-subtle font-medium">Portfolio value</p>
  <div class="flex items-baseline gap-2 mt-2">
    <span class="font-mono text-3xl font-bold text-fg-default">$847,210.45</span>
    <span class="bg-positive-bg text-positive font-mono text-xs px-2 py-0.5 rounded">+0.94% today</span>
  </div>
  <p class="text-xs text-fg-subtle mt-1">all-currencies · MXN-equiv</p>
</div>
```

### Variants

- **Default** — value + delta + sub-label.
- **No-delta** — when the metric has no comparable previous value (e.g., "Total invested" with no period). Just value + sub-label.
- **Empty** — when the value is genuinely missing (no portfolio yet), show "—" not "0.00". Sub-label can explain ("Sin movimientos aún").

---

## 5. Badge

### Purpose
Inline tag carrying a single short signal: a currency, a state, a category, or a delta.

### Variants

| Variant | Use | Tokens |
|---|---|---|
| `neutral` | Currency tags ("MXN", "USD"), categories ("Tech") | `bg-bg-muted text-fg-subtle` |
| `positive` | Gains, healthy states | `bg-positive-bg text-positive` |
| `negative` | Losses, errors | `bg-negative-bg text-negative` |
| `warning` | Caution states ("VOLÁTIL", "Approaching threshold") | `bg-warning-bg text-warning` |
| `info` | Informational ("New", "Beta") | `bg-primary-muted text-primary` |

### Sizes

`xs` (10 px font, used inside table cells) and `sm` (12 px font, used in card headers). Anything larger means it should probably be a button instead.

### Markup sketch

```erb
<span class="bg-positive-bg text-positive font-mono text-xs font-semibold px-2 py-0.5 rounded-md">+12.30%</span>
<span class="bg-bg-muted text-fg-subtle text-xs font-medium px-2 py-0.5 rounded-md">MXN</span>
<span class="bg-warning-bg text-warning text-xs font-semibold uppercase tracking-wider px-1.5 py-0.5 rounded">VOLÁTIL</span>
```

---

## 6. DataTable

### Purpose
Dense, scannable rows of records — positions, trades, alerts, news. The single component that carries the most product weight.

### Anatomy

- Container Card (see §3).
- Header row: `bg-bg-muted text-fg-subtle text-xs uppercase tracking-wider font-medium`, sticky on scroll within the card.
- Body rows: `border-b border-border-default`, `hover:bg-bg-muted/50`, `py-3 px-4`.
- All numeric cells: `font-mono text-fg-default` (or color variant).
- All gain/loss cells: text colored via `positive`/`negative` tokens; do NOT use background colors on cells (use Badge if a value needs more weight).

### Sortable columns

- Header is `<button>` with the column label + arrow icon. Click toggles asc/desc.
- Active sort column gets `text-fg-default` (vs default `text-fg-subtle`).

### Empty state inside the table

When zero rows match: collapse to a single full-width row with the EmptyState component inside (§7).

### Markup sketch

```erb
<div class="bg-bg-surface border border-border-default rounded-lg overflow-hidden shadow-sm">
  <table class="w-full">
    <thead class="bg-bg-muted">
      <tr class="text-xs uppercase tracking-wider text-fg-subtle">
        <th class="text-left px-4 py-2 font-medium">Symbol</th>
        <th class="text-right px-4 py-2 font-medium">Shares</th>
        <th class="text-right px-4 py-2 font-medium">Day Δ</th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-b border-border-default hover:bg-bg-muted/50">
        <td class="px-4 py-3 text-fg-default font-medium">AAPL</td>
        <td class="px-4 py-3 text-right font-mono text-fg-default">50</td>
        <td class="px-4 py-3 text-right font-mono text-positive">+1.20%</td>
      </tr>
    </tbody>
  </table>
</div>
```

### Rules

- **Sparklines belong inside a cell**, not a separate column header. See §9.
- **Never reverse gain/loss colors.** Green is always up; coral/red is always down.
- **Always include a units column or units tag** if the table mixes currencies.
- **Numeric cells use a glyph prefix** (`▲` / `▼` / `–`) on gain/loss values so a deuteranope can still scan the column. See Appendix A.1.

### Mobile (`<md`) — hard rule

Below the `md` breakpoint (768 px), `<table>` does not render. The DataTable re-renders as a vertical list of row-cards. This is not negotiable per Appendix A.3 — desktop tables don't read on phones.

```
┌──────────────────────────────┐
│ AAPL · 50 sh        ▲ +1.20% │
│ Apple Inc.            $9,420 │
└──────────────────────────────┘
```

- Symbol + primary identifier top-left, delta + glyph top-right.
- Secondary description bottom-left, total/market-value bottom-right.
- Whole card is the tap target → navigates to the detail screen.
- Sort/filter controls collapse into a single ghost-button "Ordenar" + `Select` row above the list.
- Sparkline renders full-width below the secondary line within the card.

---

## 7. EmptyState

### Purpose
Honest "there's nothing here yet" panel. Replaces the table/list body when there are zero records.

### Anatomy

- Centered within its container.
- Material Symbol icon at top, 32 px, color `fg-subtle`.
- Brief headline (`text-fg-default font-medium`).
- One-line subhead (`text-fg-subtle text-sm`).
- Optional single secondary action button.

### Rules

- **No emoji, no illustrations, no "Oops!".** Just say what is.
- Headline in es-MX, descriptive: "Sin movimientos aún." (not "No data" or "Empty").
- If there's an action that can populate the table, offer it. If not (e.g., "no alerts triggered today, that's normal"), don't.

### Markup sketch

```erb
<div class="flex flex-col items-center justify-center text-center py-12 px-4">
  <span class="material-symbols-outlined text-fg-subtle text-4xl">history</span>
  <p class="font-display font-semibold text-fg-default mt-3">Sin movimientos aún.</p>
  <p class="text-fg-subtle text-sm mt-1 max-w-sm">Registra tu primer trade para empezar a ver tu posición y P/L consolidado.</p>
  <%= button_tag "Registrar movimiento", class: "bg-primary hover:bg-primary-hover text-fg-inverse font-semibold px-4 py-2 rounded-md mt-4" %>
</div>
```

---

## 8. Skeleton

### Purpose
Loading placeholder. Used while server-rendered data streams in (Turbo Frames, lazy-loaded panels).

### Rules

- **Shape must match the final content.** A skeleton for a KpiCard is the same height as the loaded card, with rectangular blocks where the number and label go. Never a generic spinner.
- Animation: subtle horizontal shimmer, 1.5 s loop. Disable via `prefers-reduced-motion`.
- Color: `bg-bg-muted` for the base, `bg-border-default` for the shimmer highlight.

### Markup sketch

```erb
<div class="bg-bg-surface border border-border-default rounded-lg p-6 animate-pulse">
  <div class="h-3 w-24 bg-bg-muted rounded mb-3"></div>
  <div class="h-8 w-32 bg-bg-muted rounded mb-2"></div>
  <div class="h-3 w-20 bg-bg-muted rounded"></div>
</div>
```

---

## 9. Sparkline

### Purpose
Inline mini-chart in a table cell that gives instant trend context without leaving the row.

### Anatomy

- Inline SVG, fixed width (typically 80–120 px) and height (24 px).
- Single line stroke, 1.5 px, color matches the cell's gain/loss tone (`positive` or `negative`).
- No axis, no labels, no tooltip — this is a glance, not a chart.

### Tokens used

- `color.positive` or `color.negative` for stroke.
- No fill; trails over `bg-surface`.

### Variants

- **Trending up** — last point higher than first → `color.positive` stroke.
- **Trending down** — `color.negative` stroke.
- **Flat / stale** — when there's not enough data, render a horizontal dashed line in `color.fg.subtle` and a `Sin datos` tooltip.

### Markup sketch

```erb
<%# `points` is an array of normalized [x, y] coordinates 0..100 %>
<svg viewBox="0 0 100 24" class="w-20 h-6" preserveAspectRatio="none">
  <polyline
    points="<%= points.map { |x, y| "#{x},#{y}" }.join(' ') %>"
    fill="none"
    stroke="currentColor"
    stroke-width="1.5"
    stroke-linecap="round"
    stroke-linejoin="round"
    class="<%= trending_up ? 'text-positive' : 'text-negative' %>" />
</svg>
```

---

## 10. DonutChart

### Purpose
Compositional breakdown — a single slice of "what makes up this aggregate". Used for allocation by sector, by asset type, by geography.

### Anatomy

- SVG donut, viewBox `0 0 100 100`.
- Outer radius 40, inner radius 25 (a real donut, not a thin ring — center should accommodate a number).
- Center text: largest single segment's value (e.g., the largest sector's MXN equivalent), font-mono.
- Legend below or beside, listing all segments with their values.

### Rules

- **No more than 6 segments.** Beyond 6, group the tail into "Other".
- **Don't repeat the primary color across multiple segments.** Use a controlled subset: primary, positive, warning, negative, fg-subtle, primary-hover. Adding a 7th unique color signals you're slicing too thin.
- **Hover shows the absolute value + percentage**, not just one.

### Markup sketch

Conceptual — actual `polar_to_cartesian` math lives in a helper.

```erb
<svg viewBox="0 0 100 100" class="w-40 h-40">
  <% segments.each_with_index do |seg, idx| %>
    <path d="<%= donut_arc_d(seg, idx) %>" fill="var(--segment-color-#{idx})" />
  <% end %>
  <text x="50" y="50" text-anchor="middle" class="font-mono text-fg-default fill-current font-bold" style="font-size: 10px;">
    $<%= top_segment.value %>
  </text>
</svg>
```

---

## 11. FormField

### Purpose
Label + control + helper text + error message. Used uniformly across login, register, profile, trade entry.

### Anatomy

- Label above (`text-sm font-medium text-fg-default mb-1.5`).
- Control with `bg-bg-surface border border-border-default rounded-md`, padding `px-4 py-3`, focus ring `border-primary ring-2 ring-primary/20`.
- Helper text below (`text-xs text-fg-subtle mt-1.5`).
- Error message replaces helper text when present (`text-xs text-negative mt-1.5`), control border becomes `border-negative`.

### Variants

- **Text** — single-line input.
- **Email / password** — same shape, different `type` attribute.
- **Select** — chevron icon on the right, otherwise identical container.
- **Currency input** — currency tag (Badge `neutral`) absolutely positioned inside the right side of the input. Numeric value uses `font-mono`.
- **Date** — native `<input type="date">` styled to match; show explicit format hint as helper text ("YYYY-MM-DD").

### Markup sketch

```erb
<div>
  <%= form.label :email,
        "Email Address",
        class: "block text-sm font-medium text-fg-default mb-1.5" %>
  <%= form.email_field :email,
        autocomplete: "email",
        placeholder: "name@correo.mx",
        class: "w-full px-4 py-3 rounded-md border border-border-default bg-bg-surface text-fg-default placeholder:text-fg-subtle focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none" %>
  <% if @user.errors[:email].any? %>
    <p class="text-xs text-negative mt-1.5"><%= @user.errors[:email].first %></p>
  <% end %>
</div>
```

---

## 12. ThemeToggle

### Purpose
A control that switches between system, light, and dark themes. Persists per-user.

### Anatomy

- Three-segment switch in the navbar, next to the user avatar.
- Each segment is a Material Symbol: `desktop_windows` (system) / `light_mode` (light) / `dark_mode` (dark).
- Active segment uses `bg-primary-muted text-primary`; inactive `text-fg-subtle hover:text-fg-default`.
- Width fixed (~108 px) so the layout doesn't shift on toggle.

### Behavior

- Default: `system` (respects `prefers-color-scheme`).
- User selection: persisted in `User#theme_preference` (`enum: { system: 0, light: 1, dark: 2 }`) — not just localStorage, so the same account in two devices stays consistent.
- A small Stimulus controller on `DOMContentLoaded` reads the preference and applies/removes `html.dark`.

### Markup sketch

This is a **radio group**, not three independent buttons — wrap in `role="radiogroup"` and each segment is `role="radio"` with `aria-checked` reflecting the active mode. Arrow keys move between segments; `Space` activates. See Appendix A.1 for the full accessibility rationale.

```erb
<div class="inline-flex items-center bg-bg-muted rounded-md p-1"
     data-controller="theme"
     role="radiogroup"
     aria-label="Seleccionar tema">
  <% [:system, :light, :dark].each do |mode| %>
    <button type="button"
            role="radio"
            aria-checked="<%= current_theme == mode %>"
            data-action="theme#set"
            data-theme-mode-param="<%= mode %>"
            class="px-2 py-1 rounded text-fg-subtle data-[active=true]:bg-primary-muted data-[active=true]:text-primary">
      <span class="material-symbols-outlined text-base"><%= theme_icon(mode) %></span>
    </button>
  <% end %>
</div>
```

---

## 13. DateStamp

### Purpose
Shows the current moment at the top of dashboards and reports. Timezone-explicit. Replaces "Today, 2:08 PM"-style ambiguity.

### Anatomy

- Single inline span, monospaced.
- Format: `<DAY> · <DD MMM YYYY> · <HH:MM> <TZ>` — e.g., `MIÉ · 14 MAY 2026 · 14:08 CDMX`.
- All-caps for the day abbreviation and timezone, mixed case for the month abbreviation.
- Color `text-fg-subtle`, size `text-xs`, weight 500.

### Why

The audience opens this on Saturday mornings, possibly in a timezone different from where the market data was captured. Explicit TZ + date prevents the "is this Monday's number or Friday's?" confusion that quietly erodes trust in dashboards.

### Markup sketch

```erb
<p class="font-mono text-xs text-fg-subtle uppercase tracking-wider">
  <%= l(Time.current.in_time_zone("America/Mexico_City"), format: :dashboard_stamp) %>
</p>
```

With `:dashboard_stamp` defined in `config/locales/es-MX.yml` as `"%a · %d %b %Y · %H:%M CDMX"`.

---

## 14. Composition patterns

Which components go together for which page. Use these as starting layouts for new screens.

### 14.1 Dashboard

```
┌──────────────────────────────────────────────────────────┐
│ Navbar (logo · nav · ThemeToggle · avatar)               │
├──────────────────────────────────────────────────────────┤
│ DateStamp                                                │
│ Display heading: "Buenas tardes, <name>."                │
│                                                          │
│ [KpiCard] [KpiCard] [KpiCard] [KpiCard]   ← 4-up grid    │
│                                                          │
│ ┌─ Allocation Card ─┐ ┌─ Open positions Card ─────────┐ │
│ │ DonutChart        │ │ DataTable                     │ │
│ │ Legend            │ │ (5 rows, "Ver más" ghost btn) │ │
│ └───────────────────┘ └───────────────────────────────┘ │
│                                                          │
│ ┌─ Alerts Card ─────┐ ┌─ News Card ───────────────────┐ │
│ │ List (4 items)    │ │ List (3 items)                │ │
│ └───────────────────┘ └───────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 14.2 Portfolio detail

```
┌──────────────────────────────────────────────────────────┐
│ Navbar                                                   │
├──────────────────────────────────────────────────────────┤
│ Breadcrumb: Portfolio · default                          │
│ H1: Portfolio detail                                     │
│ KpiCard subline (value + day Δ + last sync DateStamp)    │
│                                                          │
│ Tabs: Positions · Closed · Dividends · Trade Log         │
│                                                          │
│ Filter row: Market ⌄  Currency ⌄  Held only □            │
│                                                          │
│ DataTable (all positions, dense, sparkline column)       │
└──────────────────────────────────────────────────────────┘
```

### 14.3 Auth pages (login / register)

```
┌──────────────────────────────────────────────────────────┐
│            ┌─ Centered Card (max-w-md) ─────┐            │
│            │  Logo                          │            │
│            │  Toggle: Login / Create Acct   │            │
│            │  Headline + sub                │            │
│            │  FormField × N                 │            │
│            │  Button primary "Sign in"      │            │
│            │  Footer: Terms · Privacy       │            │
│            └────────────────────────────────┘            │
└──────────────────────────────────────────────────────────┘
```

---

## 15. Don't-build and deferred components

### 15.1 Don't-build list

Components that have been considered and rejected. Adding any of these later requires a brief justification in [`brand.md §11`](./brand.md).

- **Tooltip illustrations / mascot characters.** Brand voice is sober — no Slacks-style cartoons.
- **Carousels.** If the content has a sort order, list it; if not, prioritize the top item and link the rest.
- **Sticky "buy now" CTAs.** No transactional language; no upsell affordance.
- **Achievement / streak badges.** Stockerly tracks portfolios, not engagement.
- **Animated number tickers.** Numbers update on real events, not on render. Animation suggests change where there isn't one.

### 15.2 Toasts — banned with one carve-out

- **Banned:** success toasts ("Posición guardada con éxito"), info toasts, engagement nudges. These belong inline (see Appendix A.5).
- **Allowed:** a single `AlertToast` component for **alert-rule trigger events while the user is on a non-Alerts page** — anchored bottom-right, max 1 visible at a time, auto-dismisses after 8 s, click routes to alert detail. Without this carve-out, alerts go silent when the user is elsewhere in the app, which defeats their purpose. Spec to be added when the alerts UI is implemented (Sprint 3 or later).
- **Rule:** toasts never substitute for inline state. Cross-context, time-sensitive events only.

### 15.3 Deferred components (will exist later, not yet specified)

Not banned — just not in this catalog yet. Adding any of these requires a discovery card and the §16 promotion criteria.

- **Modal / Dialog.** Implied by the `danger` Button's `data-confirm`. **Placeholder until Sprint 4:** browser-native `confirm()` for destructive confirms. No custom dialog markup in views yet. When Modal/Dialog ships, it will replace the native confirm (focus trap, `Esc` to close, return focus to opener — see Appendix A.1 keyboard expectations).
- **Tabs.** Used informally on Portfolio detail and Market detail composition sketches (§14.2, Appendix A.6.3). Until a shared Tabs component lands, render tabs as a simple `<nav>` of links with an `aria-current="page"` on the active one. No JS, no roving-tabindex yet.
- **AlertToast.** See §15.2.
- **Dropdown / Combobox.** Used informally on the Trade entry's symbol autocomplete (Appendix A.6.1). Native `<datalist>` is the placeholder.

---

## 16. When to add a new component

A new component earns a spot in this catalog when **all** of the following are true:

1. The pattern has appeared in **3 or more screens** during a single sprint.
2. There is no existing component that, with small variants, would cover the need.
3. A reviewer (Adrian, or a sub-agent acting as Renata from the expert panel) confirms it doesn't violate any brand rule (§4 of `brand.md`).

Anything below that bar should be a one-off snippet in the consuming view — not promoted to the shared catalog. The catalog stays small on purpose: shared abstractions get used wrong as they multiply.

---

## 17. When to invoke Renata (or other experts)

The expert panel is documented in [`docs/research/experts.md`](../research/experts.md). Renata Cifuentes is the UX/UI Designer voice — invoke her as a sub-agent when a UI decision is loud enough that it would be embarrassing to ship without her perspective.

**Invoke Renata before:**

- Adding a new component to this catalog (cross-check the §16 criteria + accessibility, mobile, state coverage).
- Introducing **motion/animation** anywhere (`prefers-reduced-motion` + scan-path impact).
- A redesign that touches **2 or more screens** at once (composition + hierarchy review).
- The **first beta invite**, as a final accessibility + scan-path audit on the dashboard, portfolio, alerts, market detail, and trade entry pages together.
- Considering a **violation of the §15 "don't-build" list** (e.g., "but this alert really needs a toast").
- Adding **mobile-specific patterns** beyond what Appendix A specifies.
- A copy change that affects voice consistency across 3+ screens.

**Don't invoke Renata for:**

- Single-component bug fixes on existing components (use Appendix A as the spec).
- Token value tweaks (decision lives in [`brand.md §11`](./brand.md), not in component reviews).
- Adding content within an existing component (a new row in a DataTable, a new Badge variant on an established palette).
- Internal refactors that don't change the visual output.

**How to invoke:**

Spawn a sub-agent voiced as Renata with a focused prompt. Reference Appendix A so she knows what's already been said. Keep the ask **specific** — open-ended "review this whole page" prompts get vague answers. Ask for accessibility, hierarchy, state coverage, or composition specifically.

**Other experts on this docs:**

| Expert | Invoke for |
|---|---|
| **Hiroto Tanaka** (Architecture) | Cross-context boundaries, ADRs, new bounded contexts, leak audits. |
| **Lucía Fernández** (Financial) | Calculator changes, FX handling, tax/regulatory implications, portfolio math. |
| **Esther Adler** (Scope/JTBD) | "Should this feature exist?" — vetting new features against the canonical JTBDs. |

Full profiles + when-to-use heuristics for each at [`docs/research/experts.md`](../research/experts.md).

---

## Appendix A — Renata's preliminary UX/UI input (v1)

> Captured 2026-05-14 during Sprint S2 #34 (Brand Discovery). Preliminary, complementary input on the v1 catalog. **Not the final spec** — a deeper review is expected during Sprint S3 implementation when these guidelines are battle-tested against real views.
>
> Treat this section as **guidelines for the visual migration**. When implementing a component in S3+, read both the main spec (§2–§14) AND the matching section here.

### A.1 Accessibility — additions

- **Contrast to re-check** before S3 ships:
  - `color.fg.subtle` (`#64748B`) on `color.bg.canvas` (`#FAFAF7`) — likely ~4.6:1 but close. If it lands <4.5 for body text, restrict to ≥14 px + `font-weight ≥ 500`, otherwise lift to ~`#52606D`.
  - `color.positive` (`#10B981`) on `color.positive.bg` (`#ECFDF5`) for badge text — emerald on mint historically fails AA at <14 px. If it fails, add `color.positive.fg` (~`#047857`) and keep the chip background.
  - Sparkline strokes in dark mode (`#34D399` / `#FB7185`) on `bg.surface` `#23242E` — non-text graphic, WCAG 1.4.11 wants 3:1. Likely OK; verify.
- **Focus ring** — add a token `--focus-ring: 0 0 0 3px color-mix(in oklab, var(--color-primary) 35%, transparent)` and a global rule: every interactive element uses `:focus-visible` (not `:focus`). Mouse users don't see rings; keyboard users must.
- **Color is not the only signal.** Gain/loss cells currently rely on green vs coral alone. Add a glyph prefix in numeric cells (`▲` / `▼` / `–`) at `font-mono` so a deuteranope can still scan. Cheap + improves scannability for everyone.
- **ARIA patterns to specify:**
  - *DataTable* (§6): native `<table>` is correct. Sortable column headers need `aria-sort="ascending|descending|none"` on `<th>`, inner `<button>` needs an `aria-label` like `"Sort by Day Δ, currently descending"`. Sticky header within the card is fine; don't trap focus.
  - *ThemeToggle* (§12): this is a **radio group**, not three buttons. `role="radiogroup" aria-label="Theme"`, each segment `role="radio" aria-checked="true|false"`. Arrow-key navigation between segments. Current `data-[active=true]` is fine for styling but invisible to AT.
  - *Badge* (§5): decorative badges (currency tag "MXN") need no ARIA. Stateful badges ("VOLÁTIL") already carry meaning via uppercase. Positive/negative chips without a sibling number need a visually-hidden label ("ganancia", "pérdida").
  - *Sparkline* (§9): `role="img"` + `aria-label="Trend last 30 days: up 4.2%"`. Otherwise invisible to AT.
- **`prefers-reduced-motion`** — Skeleton (§8) already addresses. Extend the rule globally near the `@theme` block:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
  }
  ```
- **Keyboard expectations per component:**
  - DataTable: `Tab` to header buttons, `Enter`/`Space` to sort, `Tab` continues into row actions. No roving-tabindex unless rows become interactive.
  - ThemeToggle: arrow keys between segments, `Space` activates.
  - Modal/Dialog (see A.5): focus trap + `Esc` to close + return focus to opener.

### A.2 Hierarchy & scan paths

Cognitive priority on a Saturday: "did anything break?" → "where am I overall?" → "what changed?" → "what should I read?" — current order is overall → composition → changed → read.

- **Alerts is buried bottom-left in §14.1.** If an alert fired Friday afternoon, the user wants to see it *before* the donut. Swap Alerts and Allocation:
  ```
  [KPI] [KPI] [KPI] [KPI]
  ┌─ Alerts ─────────┐ ┌─ Open positions ─────────────┐
  └──────────────────┘ └──────────────────────────────┘
  ┌─ Allocation ─────┐ ┌─ News ───────────────────────┐
  └──────────────────┘ └──────────────────────────────┘
  ```
  When Alerts is empty (the common case), it collapses to a single-line EmptyState — doesn't compete with positions.
- **KPI row competition.** Four mono `text-3xl` KPIs with color deltas is too much visual weight in one band. Mitigation: only the **first KPI** (Portfolio value) gets the colored delta chip; the others get a neutral mono delta with `▲`/`▼` glyph. Same information, controlled drama.
- **DateStamp placement.** Currently above the greeting. Right-align it so the greeting carries the H1 weight on the left without competing with an uppercase mono stamp directly above.
- **"Ver más" affordance.** Don't put the row count ("5 of 14") in the card *subhead*. Put it *next to* the "Ver más" ghost button: `Mostrando 5 de 14 · Ver más`. Keeps the headline clean for scanning.

### A.3 Mobile / responsive guidance

Audience uses phones — especially weekends in transit. Minimum to specify:

- **Breakpoints.** Tailwind defaults explicit: `sm 640`, `md 768`, `lg 1024`, `xl 1280`. Design target: **`md` (768)** is desktop layout; **`<md`** is mobile. Skip `xl` decoration; max dashboard width ~1200 px, centered.
- **Navbar.** Below `md`: logo + avatar visible, primary nav collapses behind a `menu` Material Symbol. ThemeToggle moves to the drawer. **Do NOT** do a bottom tab bar — this isn't a transactional app.
- **KPI row.** 4-up at `md+`, 2×2 grid at `<md`. Never single-column 4-tall.
- **DataTable → card list (mobile).** The biggest missing piece. Below `md`, the table re-renders as row-cards:
  ```
  ┌──────────────────────────────┐
  │ AAPL · 50 sh        ▲ +1.20% │
  │ Apple Inc.            $9,420 │
  └──────────────────────────────┘
  ```
  Symbol + primary value top-left, delta top-right, secondary description bottom-left, total bottom-right. Tap = navigate to detail. **Hard rule, not suggestion.**
- **Density.** Body stays 14 px on mobile — don't scale to 16 px. Audience expects density; they're not new users to be coddled. Touch targets: smallest tappable ≥ 36 px tall.
- **Sparklines** stay in the row card on mobile, full-width below the secondary line.
- **DonutChart** scales to 120 px on mobile, legend wraps below (not beside). If legend > 4 items at mobile width, collapse tail into "+N más" and reveal on tap.

### A.4 States I should add (per component)

- **Button — loading.** Preserve original width via `min-width: <measured>`, swap label for a 14 px spinner, set `aria-busy="true"`. Disable interactions while busy.
- **KpiCard — stale data.** When the price feed hasn't synced in >X minutes, render the KPI in `text-fg-subtle` (dimmed), and add a warning Badge "Datos atrasados · sync 14:08" below the sub-label. **Don't hide the number — show it dimmed.** Honest-defaults principle in action.
- **KpiCard — partial data.** When some positions synced and others didn't, the total is a partial sum. Small `?` icon next to sub-label that on hover/tap explains "3 of 12 positions not yet synced. Total excludes them."
- **DataTable — server error.** Distinct from EmptyState. Full-width row with a `warning` Badge + "No pudimos cargar tus posiciones." + a "Reintentar" ghost button. **Do not silently render zero rows** — looks like EmptyState and lies.
- **DataTable — optimistic update.** Row created/edited via Turbo Stream renders with `opacity-60` and `aria-busy="true"` until server confirms. On failure: snap back to previous state + inline error in the affected row (NOT a toast — see A.5).
- **FormField — server-side error vs client-side error.** Same visual treatment but both paths exist: Rails validation (post-submit) and async validation ("este email ya está registrado" from a `validate` endpoint).
- **Badge — interactive variant.** If a badge ever becomes clickable (filter chip), it needs hover/focus/active states. **Or explicitly say: badges are never interactive — use a Button or chip-button.**
- **EmptyState — two variants:** *actionable empty* (with button) vs *neutral empty* (no button, just one-liner). Don't render a button when there's nothing to do.
- **Skeleton — count.** Default 5 rows for DataTable loading; never exceed above-the-fold visible row count.
- **DonutChart — single-segment / fully-empty.** 100%-one-asset portfolio (early state) → render a flat circle with asset name centered, OR EmptyState. Don't show a solid ring (looks broken).
- **DateStamp — clock drift.** If client clock and server clock disagree by >2 minutes, render server time + tiny `(server)` suffix.

### A.5 "Don't-build" review (refinements to §15)

Agreed and unchanged: mascots/illustrations, carousels, streaks/achievements, animated number tickers, sticky "buy now" CTAs.

**Refined: "toasts for non-critical info"** — too absolute. Refine to:

- **Keep banned:** success toasts ("Posición guardada con éxito"), info toasts, engagement nudges. These belong inline.
- **Allow with constraints:** an `AlertToast` — anchored bottom-right, max 1 visible at a time, auto-dismisses after 8 s, click routes to alert detail, persists in the navbar bell badge after dismiss. **Genuinely time-sensitive, user opted in.** Without this, alerts go silent on non-Alerts pages and lose their purpose.
- **Rule worth keeping:** "toasts never substitute for inline state". Cross-context, time-sensitive events only.

**Implicit miss:** **Modals/Dialogs not specified** in the catalog. The danger Button's `data-confirm` implies one will exist. Either add a Dialog component now (preferred — destructive confirms, trade entry on mobile, alert detail) or **explicitly say "browser native `confirm()` is the placeholder until S4"**. Don't leave ambiguous.

### A.6 Composition patterns to add

Three Adrian will hit within S3–S4. A 4th lower-priority pattern (Settings/profile) at the end.

#### A.6.1 Trade entry (modal at `md+`, full-page at `<md`)

```
┌─ Card (max-w-lg) ──────────────────────────────────────┐
│ H2: Registrar movimiento                               │
│                                                        │
│ FormField · Tipo (Select: Compra / Venta / Dividendo)  │
│ FormField · Símbolo (autocomplete from positions+search)│
│ FormField · Cantidad         FormField · Precio unit.  │
│ FormField · Fecha            FormField · Comisión      │
│ FormField · Moneda (Select: MXN / USD)                 │
│ FormField · Notas (textarea, optional)                 │
│                                                        │
│ Inline summary: "Total: MXN 47,210.00 · equivalente …" │
│                                                        │
│ [Cancelar ghost]              [Guardar movimiento ▶]   │
└────────────────────────────────────────────────────────┘
```

Inline summary above the actions updates on every keystroke — sanity check before commit. No prescriptive language; just numbers.

#### A.6.2 Alert detail

```
┌─────────────────────────────────────────────────────────┐
│ Breadcrumb: Alertas · AAPL · RSI < 30                   │
│ H1: AAPL · RSI(14) < 30                                 │
│ Badge: ACTIVA · DateStamp last evaluation               │
│                                                         │
│ ┌─ Trigger history (DataTable, compact) ─────────────┐  │
│ │ Fecha · Valor RSI · Precio · Acción                │  │
│ └────────────────────────────────────────────────────┘  │
│                                                         │
│ ┌─ Rule definition Card ─────────────────────────────┐  │
│ │ Conditions (read-only inline form)                 │  │
│ │ [Editar regla secondary] [Pausar ghost] [Eliminar  │  │
│ │  danger]                                           │  │
│ └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

#### A.6.3 Market detail (symbol page)

```
┌─────────────────────────────────────────────────────────┐
│ Breadcrumb: Market · AAPL                               │
│ H1: AAPL · Apple Inc.       Badge: USD · NASDAQ         │
│ KpiCard subline: price · day Δ · DateStamp last sync    │
│                                                         │
│ Tabs: Resumen · Fundamentales · Noticias · Earnings     │
│                                                         │
│ ┌─ Price chart (full-width, 320 px) ─────────────────┐  │
│ │ Range selector chips: 1D · 1W · 1M · 6M · 1Y · 5Y  │  │
│ └────────────────────────────────────────────────────┘  │
│                                                         │
│ ┌─ Mi posición Card ──┐ ┌─ Métricas clave Card ──────┐  │
│ │ Qty · Avg · P/L     │ │ P/E · Div yield · Mkt cap  │  │
│ │ [+ Comprar más]     │ │                            │  │
│ │ [Ver alertas (2)]   │ │                            │  │
│ └─────────────────────┘ └────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

#### A.6.4 Settings / profile (lower priority)

Two-column at `md+`: left nav (Profile · Preferencias · Conexiones · Seguridad · Datos) + right panel of stacked FormFields grouped in Cards. Below `md`: nav collapses to a Select at top, panel renders below. **No tabs** — sparse area, persistent left nav reads more honest.

### A.7 What Renata explicitly would NOT change

Captured for the decision record — don't revisit in S3 without strong cause:

- **Lumen palette + warm-dark over slate-dark.** Cream is doing real work for Saturday morning use; resist requests to "modernize" to pure white.
- **JetBrains Mono on all numbers.** Non-negotiable. Veto proportional-digit proposals.
- **Descriptive-not-prescriptive (ADR-001) extending to UI copy.** Every es-MX entry obeys this — keep it.
- **Default to light, not system.** A closed-beta personal tool on a weekend gives a predictable first impression. Toggle is real; that's enough.
- **No mascots / no streaks / no neon.** Hold the line.
- **Catalog size ~12 components.** The §16 bar ("3 screens before promotion") is right. Resist pre-building Tabs/Modal/Tooltip "because they feel needed". Promote when used.
- **One accent color.** Indigo as the single chrome accent + green/red as the only semantic colors.
- **Focal frame logo + "observation, not transaction" framing.** Genuinely differentiated. Don't soften when someone proposes a wordmark-only "marketing variant".

### A.8 Six findings worth flagging up front

If the visual migration in S3 only fixes six things from this appendix, these six:

1. **AlertToast carve-out** (A.5) — without it, alerts go silent on non-Alerts pages.
2. **DataTable → card list pattern** (A.3) — hard mobile spec, not a hint.
3. **Stale-data and partial-data states for KpiCard** (A.4) — directly applies the brand's "honest defaults" principle.
4. **Glyph prefix on gain/loss cells** (`▲`/`▼`/`–`, A.1) — accessibility + better scannability.
5. **ThemeToggle as radio group** (A.1) — current spec is invisible to AT for state.
6. **Modal/Dialog specified or explicitly deferred** (A.5) — `data-confirm` already implies one.
