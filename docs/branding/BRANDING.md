# Stockerly Brand System

**Version:** 1.0
**Last updated:** 2026-03-10

---

## 1. Brand Overview

### Positioning

Stockerly is a professional, open-source market intelligence platform.
It is not an enterprise SaaS product, nor an amateur side project.

> Your personal market analyst, with full control over your data.

### Core Principles

- **Data before opinion** — Every feature starts with objective data, not speculation.
- **Privacy by design** — Self-hosted, no telemetry, no third-party data sharing.
- **Analytical clarity** — Clean interfaces that surface signal, not noise.
- **Self-hosted control** — Users own their infrastructure and their data.
- **Professional, not flashy** — Financial tools demand trust, not hype.

---

## 2. Logo System

All logo assets are located in [`docs/branding/`](branding/).

### Primary Logo (Horizontal)

Use in navbar, landing page, documentation, OG images, and presentations.

| Variant | File | Background |
|---------|------|------------|
| Light mode | `logo_light.svg` | For light backgrounds (`#F5F7F8`) |
| Dark mode | `logo_dark.svg` | For dark backgrounds (`#0F1923`) |

### Icon (Standalone)

Use when space is limited: favicon, app icon, collapsed sidebar, social avatar, mobile header.

| Size | File | Purpose |
|------|------|---------|
| 32x32 | `favicon.svg` | Browser favicon |
| 64x64 | `icon_64x64.svg` | Small UI contexts |
| 192x192 | `app_icon.svg` | Apple Touch Icon, PWA icon |
| 512x512 | `icon_512x512.svg` | PWA splash, app stores |

### OG Image

| Size | File | Purpose |
|------|------|---------|
| — | *Not yet available as SVG* | Social sharing (Twitter, LinkedIn, Open Graph) |

### Clear Space

The minimum clear space around the logo equals the height of the icon symbol. Never place text or other elements within that margin.

### Incorrect Usage

- Do not distort or stretch the logo
- Do not rotate the logo
- Do not apply drop shadows
- Do not use gradients outside the official palette
- Do not recolor the symbol outside the brand palette
- Do not place the logo on busy or low-contrast backgrounds

---

## 3. Color System

### Core Brand Colors

| Role | Hex | Usage |
|------|-----|-------|
| **Primary** | `#005A98` | Buttons, active links, charts, logo on light backgrounds |
| **Secondary** | `#1E293B` | Secondary headings, borders, UI containers |
| **Accent (Positive)** | `#3BC175` | Gains, positive indicators, favorable sentiment |

### Backgrounds

| Role | Hex | Usage |
|------|-----|-------|
| **Light background** | `#F5F7F8` | Landing page, docs, light mode layout |
| **Dark background** | `#0F1923` | Dashboard, dark mode layout, OG images |

### Semantic Colors

| State | Hex | Usage |
|-------|-----|-------|
| **Success** | `#3BC175` | Positive actions, confirmations, gains |
| **Warning** | `#F5A623` | Caution states, approaching thresholds |
| **Error** | `#E24C3C` | Errors, losses, destructive actions |
| **Info** | `#3B82F6` | Informational alerts, neutral highlights |

All colors should feel sober and financial. Avoid saturated neon tones.

---

## 4. Typography

All fonts are free Google Fonts. Priority: legibility of numbers, data tables, and dashboards.

### Display / Headings

**Plus Jakarta Sans** — Weights: 600, 700

Use for H1–H3, landing hero, dashboard titles. Warmer than Inter for large text while maintaining a professional feel.

### Body Text

**Inter** — Weights: 400, 500

Use for paragraphs, labels, sidebar, forms, and general UI text. Excellent readability at small sizes.

### Monospace (Financial Data)

**JetBrains Mono** — Weights: 400, 500

Use for financial tables, numeric values, KPIs, indicators (RSI, Fear & Greed), and technical logs.

Always enable tabular numbers for aligned columns:

```css
font-feature-settings: "tnum";
```

### Icons

**Material Symbols Outlined** (Google Fonts) — Variable weight, optical size 20–48.

---

## 5. Tone of Voice

### Brand Personality

Stockerly is: **Analytical, Reliable, Private, Insightful, Empowering, Precise, Independent.**

### Voice Characteristics

- Professional but human — not a corporate press release
- Clear and direct — no filler, no jargon
- Honest about limitations — no hype
- Data-driven language — "based on," "indicates," "suggests"
- Empowering, not patronizing — users are informed investors

### Avoid

- "Get rich fast" tone or implication
- Impulsive trader language ("moon," "diamond hands," "HODL")
- Exaggerated marketing claims ("revolutionary," "game-changing")
- Enterprise corporate jargon ("synergy," "leverage," "disruptive")
- Financial advice framing — Stockerly provides data, not recommendations

---

## 6. Taglines

### Primary

> Navigate the Markets with Confidence

### Alternatives

> Own Your Data. Master the Markets.

> Market Intelligence, On Your Terms.

### Secondary (Footer / About)

> Open Source Market Intelligence Platform

> Private by Design. Data-Driven by Nature.

---

## 7. UI Styling Guidelines

### Border Radius

| Context | Radius |
|---------|--------|
| Standard elements (inputs, small buttons) | `8px` |
| Cards, panels | `12px` |
| Marketing sections, hero blocks | `16px` |

### Shadows

Subtle and restrained. Never dramatic.

```css
/* Light mode */
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);

/* Dark mode */
box-shadow: 0 6px 20px rgba(0, 0, 0, 0.35);
```

### Data Visualization

- Prefer dark backgrounds for dashboard charts
- Use subtle gridlines (low opacity)
- Avoid highly saturated colors — use muted financial tones
- Green (`#3BC175`) for positive, Red (`#E24C3C`) for negative
- Never use neon colors in charts

---

## 8. Icon Philosophy

The Stockerly symbol represents:

- Structured analysis
- Trend construction through data layers
- Geometric precision
- Information clarity

It does **not** represent:

- Candlestick charts
- Upward arrows
- Dollar signs or currency symbols
- Speculation or gambling

---

## 9. Brand Feeling

Stockerly should feel like:

- An open-source financial terminal
- A market intelligence laboratory
- An independent technical analyst
- A professional tool, not a fintech toy

**Design inspirations:** Bloomberg Terminal (authority), Koyfin (modern clarity), TradingView (data density). Take the professionalism, leave the complexity.

---

## 10. Implementation (Rails + Tailwind CSS)

### Tailwind Theme

```css
@theme {
  --color-primary: #005A98;
  --color-secondary: #1E293B;
  --color-accent: #3BC175;
  --color-background-light: #F5F7F8;
  --color-background-dark: #0F1923;
  --color-success: #3BC175;
  --color-warning: #F5A623;
  --color-error: #E24C3C;
  --color-info: #3B82F6;
  --font-family-display: "Plus Jakarta Sans", sans-serif;
  --font-family-body: "Inter", sans-serif;
  --font-family-mono: "JetBrains Mono", monospace;
}
```

### CSS Utility Examples

```css
/* Primary button */
bg-primary hover:bg-[#004A80] text-white

/* Accent / positive data */
text-accent

/* Dark layout */
bg-background-dark text-gray-100

/* Financial data */
font-mono tabular-nums
```

### Google Fonts Link

```html
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@600;700&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap" rel="stylesheet">
```

---

## 11. File Reference

```
docs/branding/
├── logo_light.svg               # Full logo for light backgrounds
├── logo_dark.svg                # Full logo for dark backgrounds
├── favicon.svg                  # Browser favicon (32x32)
├── icon_64x64.svg               # Small icon
├── app_icon.svg                 # Apple Touch / PWA icon (192x192)
├── app_icon_large.svg           # Large app icon (512x512, more rounded)
├── icon_512x512.svg             # PWA splash / large icon
└── apple_touch_icon.svg         # Apple Touch Icon variant
```

---

## 12. Future Evolution

As the product matures:

- Introduce a controlled blue-to-green gradient for marketing materials
- Develop a "terminal mode" dark theme variant
- Formalize a design token system for component libraries
- Create animated logo variants for loading states

The foundation must always remain: **sobriety, precision, and trust.**
