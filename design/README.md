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

_Listing verified against the directory 2026-08-27._

| Path | What it is |
|---|---|
| `ui-kit.lib.pen` | **The design library** — tokens (our `@theme` contract) + components. Currently **0.9.0, 20 components** |
| `ui-kit.CHANGELOG.md` | Kit versions and what each bump changed |
| `flows/*.pen` | **One file per domain** — seven of them today (`auth`, `onboarding`, `cockpit`, `assets`, `alerts`, `settings`, `discover`) |
| `brand.pen` | The identity sheet (D44/D45) — sheets, not `[Flow] / Screen / State` artboards. Not a flow, which is why it has its own file and its own export section |
| `brand/` | The exported identity assets the repo consumes: `glyph.svg`, `wordmark.svg`, `wordmark.png` |
| `_playground.pen` | Experiments — inside the system (kit installed at 0.8.0 on 2026-08-27; holds `Panel · V1…V4`, the login brand-panel exploration) |
| `DECISIONS.md` | The numbered findings/decisions registry the `.pen` briefs cite |
| `CODE_CHANGES.md` | Work order for landing the redesign in code |
| `COMPONENT_INVENTORY.md` | The kit crossed against `app/views/components/` — the translation work order |
| `FIDELITY_AUDIT.md` | Per-flow measurement of how far the code is from the artboards |
| `exports/` | Canvas PNGs for review — **committed** (they must travel) |
| `references/` | Local-only device captures — **never commit: real data** (gitignored) |

## Flows

One `.pen` per domain, derived from the app's routes (`config/routes.rb`), not invented. Each flow
**re-skins the screens that already exist in code** with the new identity; the code revamp to make
the app match is tracked in [CODE_CHANGES.md](CODE_CHANGES.md). A flow earns its own file at ~3+
screens; smaller ones may merge into a neighbor.

> **Status below is the `.pen` file's, not the ERB's.** How closely the code matches each flow
> is measured in [FIDELITY_AUDIT.md](FIDELITY_AUDIT.md) — read that before taking **done · in
> review** as "the screen looks like this".

> **Vocabulary renamed 2026-08-27 (D48).** The tier ladder is now **Holdings** (was Poseo),
> **Watchlist** (was Sigo) and **Tracked** (was Rastreados), and the observation sense of
> *movimiento* is **Señales** — *movimiento* alone means a trade. The es-MX copy shipped in #364.
> **Migration is per-`.pen`, and the table below says where each file stands** — a row still
> reading `sigo` / `rastreados` has not been migrated yet. `assets.pen` is done; the other six are
> not.
>
> Adrian extended the rename to the segmented control itself, so the first tab reads **Holdings**.
> The code caught up the same day ([CODE_CHANGES.md](CODE_CHANGES.md) §13) — the design leads the
> code on nothing here now. **Lowercase `cartera` in prose is not the tier**; it means the portfolio
> and stays.

| File | Domain | Screens (from code) | Status |
|---|---|---|---|
| `flows/auth.pen` | Auth | login, 2FA/TOTP, TOTP enrollment, recovery codes, recovery-code entry, forgot, email-sent, reset — no signup (account created in onboarding) | **done · in review** — **migrated to kit 0.8.0 on 2026-08-27**: three ADR-018 artboards drawn, the email-OTP link replaced, the brief rewritten, `Panel · V1…V4` moved to `_playground.pen` |
| `flows/onboarding.pen` | Onboarding | setup, integrations, assets, complete, welcome (+ Setup desktop) | **done · in review** — its ERB revamp **landed 2026-08-25** as slice 7 ([CODE_CHANGES.md](CODE_CHANGES.md) §9b). The wizard left `Admin::` and `app/views/onboarding/` is 2.0 on every measure |
| `flows/cockpit.pen` | Cockpit (daily driver) | panorama (default/tranquilo), movimientos, asset detail (Análisis · Mi posición), consolidado | **done · in review** — **migrated to kit 0.8.0 on 2026-08-27**: six TopBars and four BottomNavs consolidated into three vendored components, `Black swan` deleted (D51), the brief rewritten, all nine exports re-shot |
| `flows/assets.pen` | Activos — the three-tier ladder (D9) + data intake | holdings, watchlist, holdings vacía, historial, registrar movimiento (sheet + con teclado), tracked, tracked·buscar | **done · in review** — **migrated to kit 0.8.0 and D48 on 2026-08-27**: the ladder renamed, the TopBar's 19px growth absorbed, all twelve exports re-shot |
| `flows/alerts.pen` | Reglas y avisos (rules + the notification inbox, D13) | reglas (default/vacío), nueva regla (sheet), bandeja, confluencia | **done · in review** — **migrated to kit 0.8.1 on 2026-08-27**: the third channel toggle dropped against the schema's two booleans, `SwitchRow` and a local `HeaderBar` vendored, the clipped bell badge fixed, Confluencia's unbuilt window gated |
| `flows/settings.pen` | Ajustes — one hub, no admin zone (D5) | hub, integraciones (+ estados), registros, estado y mantenimiento | **done · in review** — **migrated to kit 0.9.0 on 2026-08-27**: `HeaderBar` promoted from four hand-built copies, the BottomNav's double active state fixed, the `Trabajos` badge dropped against §8's documented reason, D52's `Seguridad` row added |
| `flows/discover.pen` | Descubrir — the world, not the instance (D31) | olas (default, sin datos) + Olas desktop | **done · in review** — **migrated to kit 0.8.0 on 2026-08-27**: the only flow whose shell was already fully vendored, so both bars were updated rather than consolidated; D33 closed, D41 applied, D56 raised |

Working model per flow: **(1)** read the existing screens/copy from code (source of truth for
structure + strings) · **(2)** compose them in the `.pen` with the new ui-kit · **(3)** review/feel ·
**(4)** land the ERB revamp to match, tracked in CODE_CHANGES.md.

### Desktop pass (2026-08-24, kit 0.5.0 — counts re-checked 2026-08-27)

Every flow has been through it. D4 still governs **which** screens get an artboard: one is drawn
only where the layout genuinely diverges, and the rest reflow — so **15 desktop artboards cover
six of the seven flows**, not 30. `alerts` draws none, which is why the table has seven rows and
six of them are non-empty. Counted against `design/exports/*-desktop.png`, which holds those 15
plus the kit's own `ui-kit-shell-desktop`.

| Flow | Desktop artboards | Not drawn, because |
|---|---|---|
| `auth` | Login | Same split-panel as Setup — the two doors match. The other four keep the centered card |
| `onboarding` | Setup · Integrations · Assets · Welcome | Complete inherits the wizard frame exactly |
| `cockpit` | Panorama · Asset·Análisis · Consolidado | — |
| `assets` | Holdings · Registrar movimiento · Tracked | Watchlist, Holdings vacía and the search states reuse patterns above |
| `alerts` | — | Its list and sheet are the patterns Cartera and Registrar movimiento settle |
| `settings` | Hub · Integraciones · Estado | Registros reflows; a real log table is a new component, so a decision |
| `discover` | Olas | Sin datos reflows into the same two-column shell |

The shell variant lives in the kit (`SidebarNav`, `TopBarDesktop`, `AppShellDesktop`, 0.5.0) and is
vendored per flow like everything else. Two rules came out of the pass and hold for the ERB work:
**components are not stretched to fill a column** (a wider screen buys more columns at native
width, never wider rows), and **a control is not a container** (segmented controls and forms keep
their own width whatever they are given).

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
