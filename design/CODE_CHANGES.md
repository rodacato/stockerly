# Code changes — landing the redesign in code

> The WORK ORDER for landing design-side decisions in code. A `Dn` entry in
> [DECISIONS.md](DECISIONS.md) records the finding + decision; this doc tracks its **execution**.
> Because this is a redesign, the kit leads the code — each section flips the kit from "ahead of
> code" to "1:1 mirror" once it ships.

**Rule: consolidation/adoption decisions cite MEASURED usage, not impressions.** Lead each section
with grep counts.

## 1. New `@theme` token values (D1)

**Status:** pending — waiting on the approved identity pass.

- Swap the Lumen values in `app/assets/tailwind/application.css` `@theme { }` for the redesign's,
  keeping the token **names** (contract) so views resolve unchanged. Add `--font-display /
  --font-sans / --font-mono`.
- Measure before landing: `grep -rc "bg-bg-\|text-fg-\|border-border-\|bg-positive\|bg-negative" app/views | ...`
  — confirm the contract names in use, so a value swap is safe and a rename is not needed.

## 2. Chart component (D2)

**Status:** pending — design first.

- Add `lightweight-charts` via importmap; a `PriceChart` Stimulus controller fed by our existing
  close series (the same data behind RSI/Bollinger/SMA). No TradingView iframe.

## 3. Cockpit components → ERB partials

**Status:** pending — design first.

- The `cockpit.pen` components map 1:1 to `app/views/components/`. Translate after the flow is
  approved (per README fidelity loop). Confluence engine (Light 2 + window) is NOT built here —
  gated on its 4-filter card (D3).
