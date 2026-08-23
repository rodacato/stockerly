# Design decisions — open questions & findings (D1–Dn)

> **The registry the `.pen` files point at.** Briefs in `flows/*.pen` and warning notes in
> `ui-kit.lib.pen` cite these by number. Keep entries after resolution — record the outcome
> instead of deleting; the reasoning is the useful part.

**Status:** 8 entries · 7 resolved · 1 open · 0 🔴 high-impact · 0 🐞 app bugs

**How entries work.** A `Dn` is a finding logged when a call isn't purely mechanical. In a
normal migration the design matches the code; here (a **redesign**) the design leads on visual
values, so entries also record forward design calls — each with what we picked and why.

---

## Decisions to make (design calls)

| # | Decision | Values in play | Verdict |
|---|---|---|---|
| **D1** | Palette values for the `@theme` token contract | Muted fresh values · Code's Lumen values | ✅ **Adopt the code's Lumen palette (reused contract, code's values).** First tried muted "fresh" values (ink-blue `#2B4B6F`); Adrian found them conservative and preferred the code's brighter, more cheerful indigo (`#5B6CFF`) + colorful semantics. So **design and code converge on color** — the color revamp becomes a no-op. The modern/youthful feel comes from **type + shape**, not a bespoke palette: display = **Plus Jakarta Sans** (the code's), **rounder radii** 8/12/16/20. Light+dark lifted from `app/assets/tailwind/application.css`. Reverses the earlier "fresh values" call — 2026-08-23. |
| **D2** | Charts: how to render them | TradingView iframe · `lightweight-charts` (OSS) | ✅ **`lightweight-charts` (TradingView's MIT lib), our data.** An iframe leaks the watchlist to a third party (breaks self-hosted/outbound-only ethos), can't show MXN/historical-FX, is heavy and unbrandable. The OSS lib renders our own series, self-hostable via importmap. Iframe stays a fallback only for a chart type we can't render (unlikely). Recommended 2026-08-23. |
| **D3** | Confluence "3-light" (`semáforo`) — the distilled signal | — | ⏳ **Open (design only; build gated).** Design the full target; Light 1 (RSI<30 & below lower BB / RSI>70 & above upper BB) and Light 3 (MA/MACD trend change) are groundable from existing observations; Light 2 + the time-window are net-new and render as "próximamente". The **engine** waits on a 4-filter discovery card before any build. See `flows/cockpit.pen` brief + `../redesign/design/prompts/02`. |
| **D4** | Responsive: how to handle mobile + desktop | Every screen ×2 · Mobile-first + selective desktop | ✅ **Mobile-first is canonical (390×844). A desktop artboard is drawn ONLY when the layout genuinely diverges (Setup split-panel; cockpit/asset-detail master-detail), when Adrian requests it, or when a dense screen needs its distribution checked.** Everything else reflows (`max-w` centered) via Tailwind — mobile artboard + a one-line desktop note in the brief, no separate artboard. `AppShell`/nav is the one component with two variants (mobile bottom-tab vs desktop top/side). Confirmed with Adrian 2026-08-23. |
| **D5** | Onboarding — account framing | "admin account" · single-user | ✅ **Single-user: "Crea tu cuenta" / "la única cuenta de tu instancia"; drop all "admin" framing.** The code revamp updates the setup copy to match. |
| **D6** | Onboarding — copy language | English (current) · es-MX | ✅ **es-MX in the design** (setup/integrations/assets/complete ship English today); this drives the code revamp to translate them. Storage mechanism (hardcoded es-MX vs adopting i18n-tasks) is decided at the onboarding code-revamp step — it re-opens [ADR-0007](../docs/architecture/adr/0007-defer-i18n-adoption.md), so it is Adrian's call, not a design decision. |
| **D7** | Canvas artboard sizing (minimum) | — | ✅ **Mobile: 390 × 844 minimum** — width fixed 390; height **≥ 844** (a phone-viewport floor, informed by Galaxy-S22+-class devices). **Desktop: 1280 × 800 minimum.** A screen may **exceed** the min height for scrollable content, but never go under it, so every artboard reads at a consistent size. Confirmed with Adrian 2026-08-23. |
| **D8** | Source-of-truth stance for the redesign | Code-fidelity (mirror) · Design-led (code as reference) | ✅ **Design-led.** From 2026-08-23 the code is **reference, not a spec to replicate** — we design the best product UX/UI and the code is later revamped to match (these `.pen` designs guide the implementation). **Grounding caveat:** the code still anchors *what's buildable* — real data/indicators, constraints (single-user, free-tier, es-MX), domain concepts, existing copy — so we design nothing that can't exist. Structure/layout/UX are ours; grounding is the code's. |

## Changes to make in code (once decisions land)

Execution lives in [CODE_CHANGES.md](CODE_CHANGES.md).

## Out of scope (confirmed)

- No trade execution, no backtester, no strategy engine, no buy/sell advice — the app shows the
  *state* of the user's own rules, descriptive only ([[project-vision]] non-audience).
