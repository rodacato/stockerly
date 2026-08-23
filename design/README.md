# Design — Pencil workflow

Everything about Stockerly's design lives here. Read this before touching a `.pen`. It doubles
as context for AI agents.

> **Stockerly is mid-REDESIGN** (pivot 2026-08-20, [ADR-0010](../docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)):
> a self-hosted single-user "decision cockpit". This `design/` is the **redesign-target system —
> it runs ahead of the code**, which still shows the old look. That inverts the usual rule below,
> so read the adaptation carefully.

## The two rules — adapted for a redesign

1. **Design-led; code is reference (D8).** We design the best product UX/UI — the code is **not a
   spec to replicate**, it is later revamped to match (these `.pen` files guide the implementation).
   The code still **grounds** the work: what data/indicators actually exist, the real constraints
   (single-user, free-tier, es-MX), domain concepts, and existing copy — so we design nothing that
   can't be built. Structure and UX are ours; grounding is the code's. New copy is es-MX.
2. **Don't dedupe or promote into the kit unless asked.** No live propagation; every kit change
   is manual re-vendor across consumers. A resemblance is a note, not a task.

When the redesign lands in code, [CODE_CHANGES.md](CODE_CHANGES.md) tracks it and the kit stops
being "ahead" and becomes a 1:1 mirror again.

## What's here

| Path | What it is |
|---|---|
| `ui-kit.lib.pen` | **The design library** — tokens (our `@theme` contract, fresh values) + components |
| `ui-kit.CHANGELOG.md` | Kit versions and what each bump changed |
| `flows/*.pen` | **One file per domain**. First: `cockpit.pen` (panorama → detalle → confluencia) |
| `_playground.pen` | Experiments — inside the system (vendors the kit like any flow) |
| `DECISIONS.md` | The numbered findings/decisions registry the `.pen` briefs cite |
| `CODE_CHANGES.md` | Work order for landing the redesign in code |
| `exports/` | Canvas PNGs for review — **committed** (they must travel) |
| `references/` | Local-only device captures — **never commit: real data** (gitignored) |

## Flows

One `.pen` per domain, derived from the app's routes (`config/routes.rb`), not invented. Each flow
**re-skins the screens that already exist in code** with the new identity; the code revamp to make
the app match is tracked in [CODE_CHANGES.md](CODE_CHANGES.md). A flow earns its own file at ~3+
screens; smaller ones may merge into a neighbor.

| File | Domain | Screens (from code) | Status |
|---|---|---|---|
| `flows/auth.pen` | Auth | login, 2FA/TOTP, forgot, email-sent, reset — no signup (account created in onboarding) | **done · in review** |
| `flows/onboarding.pen` | Onboarding | setup, integrations, assets, complete, welcome (+ Setup desktop) | **done · in review** |
| `flows/cockpit.pen` | Cockpit (daily driver) | dashboard/panorama, market/asset detail, portfolio | in progress |
| `flows/assets.pen` | Assets + data intake | trades, positions, watchlist, admin asset CRUD | scaffold |
| `flows/alerts.pen` | Alerts / hard rules | alerts index, rule create/edit, confluence | scaffold |
| `flows/settings.pen` | Settings + admin | profile (password/prefs/currency), admin integrations/pool-keys/logs/settings | scaffold |

Working model per flow: **(1)** read the existing screens/copy from code (source of truth for
structure + strings) · **(2)** compose them in the `.pen` with the new ui-kit · **(3)** review/feel ·
**(4)** land the ERB revamp to match, tracked in CODE_CHANGES.md.

## Design inputs (the redesign discovery)

The hub `../redesign/` (gitignored, local) holds the thinking this design serves:
- `design/product-concept.md` — the decision-cockpit soul (one screen, ~20 min, mobile).
- `design/prompts/01–03` — the validated Claude Design prompts (panorama+detalle, confluence
  semáforo, visual identity). The components they produced seed this kit.
- The confluence "3-light" rule (`reglas duras sin corazón`) — see DECISIONS + `cockpit.pen` brief.

## Canvas conventions

- Base frame: **390×844 minimum** (mobile; width 390, height **≥ 844** — a screen may be taller
  for scrollable content, never shorter, so all artboards read consistently — see D7). Desktop
  artboards: **1280×800 minimum**, only where the layout genuinely diverges (master-detail, etc.).
- Naming: `[Flow] / [Screen] / [State]`. Rows left → right, one per journey, **brief frame first**.
- **Tokens only — zero hex in a flow.** A value the kit lacks is a kit gap: log it.
- Charts are a **first-class focal element** (fixes "no sé a dónde mirar"), rendered from our own
  data — see D2 (lightweight-charts, not TradingView iframes).
- Touch targets ≥ 44pt; AA contrast through tokens.

## The kit + vendoring

Core/shared components → the kit. Feature-local → the flow. Flows **vendor** the kit at a pinned
`kit-version-source` (Pencil can't cross-reference files); bumps follow the CHANGELOG rules.
Being behind is fine; **diverging is not** — install every token in every flow.

## Team workflow

1. Design changes ride PRs like code — atomic with the implementing code when possible.
2. One person per `.pen` at a time (JSON merges badly). Kit changes get review.
3. No auto-save: **save often, commit often**.
4. Nothing leaves `_playground.pen` for `flows/` without cleanup + approval.
5. Export PNGs of changed flows into `exports/` (committed).

## Fidelity loop (design ↔ code), once the redesign lands

Open the flow → read its brief → design with vendored components → implement (the `.pen`
components map 1:1 to `app/views/components/`) → screenshot the rendered app, overlay at 50% on
the design, fix drift in the design first, then the code.
