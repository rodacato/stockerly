# Stockerly Design Tokens — Lumen

> Concrete values for the Lumen brand kit. Rationale lives in [`brand.md`](./brand.md); how each token gets consumed by components lives in [`components.md`](./components.md).

The reference implementation target is **Tailwind CSS 4** with `darkMode: 'class'`. Tokens are declared once in the light `@theme` block and overridden inside `:where(html.dark, [data-theme="dark"])` so dark mode flips at the CSS-variable layer (every Tailwind utility that resolves to a token picks it up automatically).

---

## 1. Color tokens

### 1.1 Reference table

| Token | Light | Dark | Notes |
|---|---|---|---|
| `color.primary` | `#5B6CFF` | `#7B89FF` | Lifted in dark to keep ≥4.5:1 on `bg.canvas`. |
| `color.primary.hover` | `#4757E3` | `#9098FF` | |
| `color.primary.muted` | `#EEF0FF` | `#2A2E55` | Soft fill for selected nav items, focus rings, hover backgrounds. |
| `color.bg.canvas` | `#FAFAF7` | `#1A1B23` | Page-level background. Warm in both modes. |
| `color.bg.surface` | `#FFFFFF` | `#23242E` | Cards, modals, popovers. |
| `color.bg.muted` | `#F4F2EC` | `#2B2D38` | Secondary surface — table header rows, disabled states. |
| `color.fg.default` | `#0F172A` | `#F8FAFC` | Primary text. |
| `color.fg.subtle` | `#64748B` | `#94A3B8` | Secondary text, captions, placeholder. |
| `color.fg.inverse` | `#FFFFFF` | `#0F172A` | Text on primary-filled buttons and badges. |
| `color.border.default` | `#E7E3D9` | `#33353F` | Card borders, table dividers, input outlines. |
| `color.border.strong` | `#D6D1C4` | `#3E414C` | Focused / active borders. |
| `color.positive` | `#10B981` | `#34D399` | Gains, success states. |
| `color.positive.bg` | `#ECFDF5` | `#0F2E25` | Badge backgrounds, subtle success surfaces. Dark variant is deep+low-chroma — won't glow against `bg.surface`. |
| `color.negative` | `#F43F5E` | `#FB7185` | Losses, errors. |
| `color.negative.bg` | `#FFF1F3` | `#3A1620` | Subtle error surfaces. |
| `color.warning` | `#F59E0B` | `#FBBF24` | Caution states, approaching thresholds. |
| `color.warning.bg` | `#FFFBEB` | `#3A2A0C` | |
| `color.info` | `#5B6CFF` | `#7B89FF` | **Alias of `color.primary`.** Stockerly only has one accent; the alias keeps consumer code semantically clear without inviting a second hue. |
| `color.info.bg` | `#EEF0FF` | `#2A2E55` | |

### 1.2 Tailwind 4 `@theme` block

```css
@import "tailwindcss";

/* Stockerly · Lumen — light is the default theme. */
@theme {
  --color-primary:           #5B6CFF;
  --color-primary-hover:     #4757E3;
  --color-primary-muted:     #EEF0FF;

  --color-bg-canvas:         #FAFAF7;
  --color-bg-surface:        #FFFFFF;
  --color-bg-muted:          #F4F2EC;

  --color-fg-default:        #0F172A;
  --color-fg-subtle:         #64748B;
  --color-fg-inverse:        #FFFFFF;

  --color-border-default:    #E7E3D9;
  --color-border-strong:     #D6D1C4;

  --color-positive:          #10B981;
  --color-positive-bg:       #ECFDF5;
  --color-negative:          #F43F5E;
  --color-negative-bg:       #FFF1F3;
  --color-warning:           #F59E0B;
  --color-warning-bg:        #FFFBEB;
  --color-info:              #5B6CFF;
  --color-info-bg:           #EEF0FF;
}

/* Dark mode overrides — toggled via html.dark (Tailwind 4 darkMode: class). */
@layer base {
  :where(html.dark, [data-theme="dark"]) {
    --color-primary:        #7B89FF;
    --color-primary-hover:  #9098FF;
    --color-primary-muted:  #2A2E55;

    --color-bg-canvas:      #1A1B23;
    --color-bg-surface:     #23242E;
    --color-bg-muted:       #2B2D38;

    --color-fg-default:     #F8FAFC;
    --color-fg-subtle:      #94A3B8;
    --color-fg-inverse:     #0F172A;

    --color-border-default: #33353F;
    --color-border-strong:  #3E414C;

    --color-positive:       #34D399;
    --color-positive-bg:    #0F2E25;
    --color-negative:       #FB7185;
    --color-negative-bg:    #3A1620;
    --color-warning:        #FBBF24;
    --color-warning-bg:     #3A2A0C;
    --color-info:           #7B89FF;
    --color-info-bg:        #2A2E55;
  }
}
```

### 1.3 How to use in views

Reference tokens through Tailwind utility classes. The `--color-*` custom properties map to Tailwind's `bg-*`, `text-*`, `border-*` namespaces.

```erb
<%# Card on canvas background %>
<div class="bg-bg-surface border border-border-default rounded-lg shadow-sm">
  <h3 class="text-fg-default">Posiciones abiertas</h3>
  <p class="text-fg-subtle text-sm">5 of 14, sorted by weight</p>
</div>

<%# Positive change indicator %>
<span class="bg-positive-bg text-positive px-2 py-0.5 rounded-md font-mono text-xs">
  +1.20%
</span>

<%# Primary action button %>
<%= button_tag "Registrar movimiento",
      class: "bg-primary hover:bg-primary-hover text-fg-inverse font-semibold px-4 py-2 rounded-md" %>
```

**Never hardcode hex values in views.** If a color doesn't exist as a token, add a token first.

---

## 2. Typography tokens

### 2.1 Type scale

| Role | Family | Weight | Size | Line-height | Letter-spacing |
|---|---|---|---|---|---|
| Display | Plus Jakarta Sans | 700 | 40 px / 2.5 rem | 1.1 | -0.030 em |
| H1 | Plus Jakarta Sans | 700 | 28 px / 1.75 rem | 1.15 | -0.025 em |
| H2 | Plus Jakarta Sans | 600 | 22 px / 1.375 rem | 1.2 | -0.020 em |
| H3 | Plus Jakarta Sans | 600 | 18 px / 1.125 rem | 1.3 | -0.015 em |
| Body | Inter | 400 | 14 px / 0.875 rem | 1.55 | -0.005 em |
| Body strong | Inter | 500 | 14 px / 0.875 rem | 1.55 | -0.005 em |
| Caption | Inter | 400 | 12 px / 0.75 rem | 1.50 | 0 |
| Numeric | JetBrains Mono | 500 | 14 px / 0.875 rem | 1.40 | -0.005 em |

### 2.2 Font family tokens

```css
@theme {
  --font-display: "Plus Jakarta Sans", ui-sans-serif, system-ui, sans-serif;
  --font-sans:    "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-mono:    "JetBrains Mono", ui-monospace, SFMono-Regular, monospace;
}
```

### 2.3 Font loading

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link
  rel="stylesheet"
  href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap"
>
```

`font-display: swap` is intentional — system fallback shows immediately while the web font loads, avoiding a flash of invisible text on slow connections.

### 2.4 Numeric typography rule

**All numbers (prices, percentages, KPIs, table cells) use `font-mono`.** This is non-negotiable: Inter's variable-width digits don't align in tables, and column-density tables are core to the product.

```erb
<%# Right: tabular figures align %>
<td class="font-mono text-fg-default">1,000.00</td>

<%# Wrong: proportional figures drift %>
<td class="font-sans text-fg-default">1,000.00</td>
```

---

## 3. Other tokens

### 3.1 Border radius

| Token | Pixels |
|---|---|
| `radius.sm` | 6 |
| `radius.md` | 9 |
| `radius.lg` | 12 |
| `radius.xl` | 16 |
| `radius.full` | 9999 (circle) |

Typical use: `sm` for inline tags / chips, `md` for buttons and inputs, `lg` for cards, `xl` for modals and large panels, `full` for avatars and circular icons.

### 3.2 Shadow scale

| Token | Light | Dark |
|---|---|---|
| `shadow.sm` | `0 1px 2px rgba(20, 18, 12, 0.05)` | `0 0 0 1px rgba(255, 255, 255, 0.03), 0 2px 6px rgba(0, 0, 0, 0.40)` |
| `shadow.md` | `0 1px 2px rgba(20, 18, 12, 0.04), 0 8px 24px rgba(20, 18, 12, 0.05)` | `inset 0 1px 0 rgba(255, 255, 255, 0.03), 0 12px 32px rgba(0, 0, 0, 0.45)` |
| `shadow.lg` | `0 4px 12px rgba(20, 18, 12, 0.06), 0 24px 48px rgba(20, 18, 12, 0.08)` | `inset 0 1px 0 rgba(255, 255, 255, 0.04), 0 24px 60px rgba(0, 0, 0, 0.55)` |

Note the dark-mode shadows use an `inset` highlight + much stronger main shadow — this is how dark surfaces still get depth without looking flat.

### 3.3 Spacing scale

**Tailwind defaults.** Base unit `0.25 rem` (4 px), scale `spacing[0..96]`. No custom additions.

If a screen demands odd spacing (e.g., 18 px or 22 px), default to picking the nearest Tailwind value (16 or 20 / 20 or 24) before introducing a custom token. Custom spacing is a code smell — usually a sign the rhythm is broken elsewhere.

---

## 4. Migration notes (S3 onward)

This file is the implementation contract for the visual migration scheduled in Sprints S3–S6. The current `app/assets/tailwind/application.css` still ships the pre-Lumen palette (`--color-primary: #005A98` and friends) so existing views don't break mid-sprint. To migrate cleanly:

1. **S3 first migration commit:** copy the `@theme` block from §1.2 into `app/assets/tailwind/application.css`, replacing the pre-Lumen tokens. Verify auth pages and dashboard at a glance — they'll change color but layout should hold.
2. **S3–S6 component-by-component:** when touching a view, swap any hex literals or pre-S2 tailwind classes to the new token-named classes (`bg-bg-surface`, `text-fg-default`, etc.).
3. **Sprint S6 close:** delete any remaining references to pre-Lumen color names from views and the theme block.

`audit-entropy.sh` already counts hardcoded color literals in views; track the count down each sprint as a proxy for migration progress.

### 4.1 Foreground (`-fg`) variants — WCAG AA pattern (S04)

Semantic tokens like `success`, `error`, `warning`, `info` are tuned for *backgrounds* and *accents* at their saturated mid-tone hue. When used as **text on a light background**, they fail WCAG AA contrast (4.5:1) — the saturated greens / reds / ambers / blues land between 2.2:1 and 4.0:1 on white.

Each colored token therefore has a matching `-fg` variant tuned for text legibility on light surfaces:

| Token | Use | Hex (light) |
|---|---|---|
| `success` | bg, accents, dark-mode text | `#3BC175` |
| `success-fg` | light-mode text | `#1A7C49` |
| `warning` | bg, accents, dark-mode text | `#F5A623` |
| `warning-fg` | light-mode text | `#B5760A` |
| `error` | bg, accents, dark-mode text | `#E24C3C` |
| `error-fg` | light-mode text | `#B5331E` |
| `info` | bg, accents, dark-mode text | `#3B82F6` |
| `info-fg` | light-mode text | `#1D4ED8` |

**Pattern for any colored text:** `text-X-fg dark:text-X`. The light-mode `-fg` variant is contrast-safe on the `bg-X/10` tint and on plain white. The dark-mode base `text-X` is contrast-safe on dark slate (≈5:1 on `bg-slate-900`).

**Pattern for background tints:** `bg-X/10 dark:bg-X/20`. The opacity step compensates for slightly different perceived contrast across modes.

**Pattern for borders:** `border-X/20 dark:border-X/30`. Same opacity rationale.

Established in PR #63 (S04) after Gemini caught the contrast failure on a first-pass migration that collapsed `text-X-700 light / text-X-400 dark` into a single `text-X`. Reference example: any of the S05 slice files (`portfolios/_positions_table.html.erb`, `market/_listings_table.html.erb`, `admin/integrations/index.html.erb`).

### 4.2 Heatmap exception — `dashboard/_fear_greed_card.html.erb`

The Fear & Greed card uses a **5-tier color scale** (red → orange → amber → lime → emerald) representing the 0–100 sentiment score. This is a true heatmap: the intermediate hues (orange, lime) do not map to any of the `success / warning / error / info` semantic roles, and inventing `color-scale-low / mid / high` tokens for a single consumer would be ceremony without value.

**Decision (S05):** leave the F&G card with hardcoded palette colors as a documented exception. The audit script will continue to count its ~7 hits forever; that's accepted noise in the metric.

**Re-evaluation trigger:** if a second view appears that needs a multi-tier heatmap scale (3+ semantic buckets that don't map to existing tokens), define `color-scale-*` tokens at that point and migrate both views together. The S04 retro carry-over set the rule "≥2 true heatmaps → define tokens"; the S05 audit found only F&G qualifies, so the exception stands.

Bucket-style 3-tier indicators (strong/medium/weak, e.g., the trend-strength bar in `_listings_table`) are **not** heatmaps — they map cleanly to `success / warning / error` and follow the standard pattern.

## 5. When to update this doc

- A new token is added (e.g., a chart-specific palette extension) — add it to §1.1 and the `@theme` block.
- A token value changes — update both the table and the CSS block; note the change in [`brand.md §11`](./brand.md) decision record.
- A new font is introduced — extend §2 with the new family + loading snippet, and document why (with the bar set high; three families is already a lot).

Never edit `brand.md` and `tokens.md` independently; they must stay in sync.
