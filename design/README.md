# Design — Pencil workflow

Everything about Stockerly's design lives here. Read this before touching a `.pen`. It doubles
as context for AI agents.

> **The redesign landed. D8 is retired ([D78](DECISIONS.md), 2026-09-05).** Stockerly pivoted
> 2026-08-20 ([ADR-0010](../docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md))
> to a self-hosted single-user "decision cockpit", and for that revamp this `design/` ran **ahead of
> the code**. It no longer does: all twenty `CODE_CHANGES.md` sections shipped, the pre-2.0 palette
> is at zero across every view directory, and the last `.pen` write predates the last `app/views`
> write by a week. **The kit is a 1:1 mirror again**, which is the rule below.

## The two rules

1. **The code is the mirror (D78, retiring D8).** The kit and the flows reflect what ships: on
   style, tokens, structure and copy the **code wins and the artboard is amended** — the X8
   precedent (#417), generalized. Designing ahead is now a deliberate act per screen, not the
   standing posture: it needs a build-or-retire verdict, not just an artboard. The code also still
   **grounds** the work — what data/indicators actually exist, the real constraints (single-user,
   free-tier, es-MX), domain concepts, existing copy. New copy is es-MX.
2. **Don't dedupe or promote into the kit unless asked.** No live propagation; every kit change
   is manual re-vendor across consumers. A resemblance is a note, not a task.

**D78's carve-out, which is the part a mirror rule would erase:** three screens are drawn and
unbuilt — `Movimientos` (CKP-1), the empty state's demo and CSV doors (ACT-1) and `Confluencia`
(ALR-1). **The rule change does not retire them.** Each owes an explicit verdict, because two of
them are failures the vision says the 2.0 must fix and one was un-gated by D42.

## What's here

_Listing verified against the directory 2026-08-27._

| Path | What it is |
|---|---|
| `ui-kit.lib.pen` | **The design library** — tokens (our `@theme` contract) + components. Currently **0.9.0, 20 components** |
| `ui-kit.CHANGELOG.md` | Kit versions and what each bump changed, plus the live **Open kit gaps** list |
| `flows/*.pen` | **One file per domain** — seven of them today (`auth`, `onboarding`, `cockpit`, `assets`, `alerts`, `settings`, `discover`) |
| `brand.pen` | The identity sheet (D44/D45) — sheets, not `[Flow] / Screen / State` artboards. Not a flow, which is why it has its own file and its own export section. **On kit 0.9.0 since 2026-08-27** |
| `brand/` | The exported identity assets the repo consumes: `glyph.svg`, `wordmark.svg`, `wordmark.png` |
| `_playground.pen` | Experiments — inside the system (kit installed at 0.8.0 on 2026-08-27; holds `Panel · V1…V4`, the login brand-panel exploration) |
| `DECISIONS.md` | The numbered findings/decisions registry the `.pen` briefs cite |
| `CODE_CHANGES.md` | Work order for landing the redesign in code |
| `V2_REMAINING.md` | **Where the migration stands and what is left** — the 2.0 contract measurement, the kit-to-code crossing, and the punch list. Retired and replaced `FIDELITY_AUDIT.md` + `COMPONENT_INVENTORY.md` on 2026-08-28 |
| `exports/` | Canvas PNGs for review — **committed** (they must travel) |
| `references/` | Local-only device captures — **never commit: real data** (gitignored) |

## Flows

One `.pen` per domain, derived from the app's routes (`config/routes.rb`), not invented. Each flow
**re-skins the screens that already exist in code** with the new identity; the code revamp to make
the app match is tracked in [CODE_CHANGES.md](CODE_CHANGES.md). A flow earns its own file at ~3+
screens; smaller ones may merge into a neighbor.

> **The kit 0.8.0 → 0.9.0 migration closed 2026-08-27.** All ten `.pen` files are on the kit —
> `ui-kit`, `alerts`, `settings`, `onboarding` and `brand` at **0.9.0**, the rest at **0.8.1**. The
> split is not drift: 0.8.1 was a token-and-treatment patch every consumer took, 0.9.0 added
> `HeaderBar` and moved only the flows that vendor it. Divergence is zero, verified by comparing
> **values**, not names. `MIGRATION.md` tracked that work and was deleted on close, per its own
> first line — the durable parts are here, in `ui-kit.CHANGELOG.md`'s gap list, and in D53/D57/D58/D59.

> **Status below is the `.pen` file's, not the ERB's.** How closely the code matches each flow
> is measured in [V2_REMAINING.md](V2_REMAINING.md) — read that before taking **done · in
> review** as "the screen looks like this". **That file carries the running count and this line is a
> copy of it, so it goes stale on its own** — it read `19 closed and 33 open` while V2_REMAINING said
> `22 and 32`, and both were wrong against a recount. As of 2026-08-29: **23 closed and 32 open,
> four of them red.** Re-derive from V2_REMAINING's own commands rather than trusting this
> sentence.
>
> **The code caught up on three flows on 2026-08-28.** `auth` gained its three TOTP screens and the
> second factor at login; `onboarding` gained the Seguridad step and went to four; `assets` gained
> `Historial`, which absorbed `/trades`. What is left per flow is in `V2_REMAINING.md`, not here.

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
| `flows/onboarding.pen` | Onboarding | setup, integrations, assets, **seguridad**, complete, welcome (+ Setup/Integrations/Assets/Welcome desktop) | **done · in review** — **migrated to kit 0.9.0 on 2026-08-27**: D52's fourth step drawn and the Stepper moved 3 → 4, VOO/CETES split to catch up to the locale's five categories, the stale auth-coherence flag retired |
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

## Working a `.pen` — what this migration paid to learn

Operating notes, not preferences. Each cost a mistake.

- **A `.pen` write reaches disk with a LAG, and Pencil does not auto-save.** `git status` showing
  *modified* proves that *something* landed, not that everything did — one commit shipped a stale
  brief that way. **Verify by grepping for the specific content you wrote**, and when the grep count
  is ambiguous, confirm with a `Get` query: prose in a brief matches the same strings as a live
  artboard.
- **A raw grep count is not a node count, and reading it as one will send you chasing ghosts.** The
  serialized `.pen` holds strings that are not live nodes: after renaming two texts on 2026-08-28,
  `grep -c` fell 4 → 2 while `Get` reported exactly two nodes, both already renamed, and the
  screenshot confirmed it. **A grep answers *did the write land*; only `Get` answers *how many
  nodes say this*, and only a screenshot answers *what does a reader see*.** Use the count as a
  direction, never as a total.
- **Reconcile against the kit's list, never against the diff — and compare values, not names.**
  Installing only the new tokens is how `auth.pen` and `onboarding.pen` went four minor versions
  without `scrim`. Comparing membership but not values is how `brand.pen` diverged on `info-fg`
  through a sweep designed to catch exactly that. Membership and equality are two checks.
- **Measure before replacing.** Vendoring looks mechanical and is not: three `NavRow` copies were
  drift and a fourth was a deliberate accent; two `SwitchRow` rows were drift and a third was a real
  OFF state; `alerts`' back-header looked like `cockpit`'s and is a different component. Replacing
  all of them would have erased real hierarchy while calling it consistency.
- **`Get` does not descend into instances without `resolveInstances: true`.** An artboard can change
  visually without any of its own nodes changing, because the change lives in a component master —
  the first query for *which artboards to re-export* missed four that way.
- **Measure `ctx.bounds` in a different `execute` than the one that writes.** In the same call it
  returns pre-reflow positions and reports clipping that is not real.
- **Verify the artboard names before writing.** Node ids repeat across flow files because the flows
  were created by duplicating each other; an id never proves which file you are in.
- **`Export` resolves its path from the repo root, not from the `.pen`,** and names files by node id.
  An export nobody renames survives as a file nobody can identify — one did, for weeks.
- **A claim about code carries `file:line`.** A handoff item cost four tool calls to disprove because
  it had neither. A decision is only as current as the ADR it cites: read the chain forward
  (ADR-001 → 013 → 014) before executing anything that rests on the first one.
- **After a merge, verify master by content, not by SHA.** A squash or rebase merge rewrites SHAs, so
  `git branch --contains` proves nothing; #366 merged only its first commit and nobody noticed until
  the next session read the file.
- **One person per `.pen` at a time governs WRITING**, because JSON merges badly. Reading a second
  file to check a claim costs nothing — and not reading it is how a false warning survived months.

### Measure the file before you trust a document about it

Any number in `design/*.md` is a dated observation. Run this first; it is one call and it answers
what four hand-maintained columns used to:

```js
const v = GetVariables().variables;
Print("kit:", v["kit-version-source"]?.value, "| vars:", Object.keys(v).length,
      "| chart-1:", !!v["chart-1"], "| info-fg:", JSON.stringify(v["info-fg"]?.value));
Get((n, c) => { if (c.depth > 0) { c.skipChildren(); return undefined; }
  return Print(n.reusable ? "COMPONENT" : "artboard", "|", n.name, "|", n.id, "|",
               Math.round(c.bounds.width) + "x" + Math.round(c.bounds.height)); });
Get(n => n.type === "frame" && !n.reusable &&
     ["TopBar","BottomNav","TopBarDesktop","SidebarNav","SwitchRow","Header","HeaderBar"].includes(n.name) &&
     Print("LOCAL COPY |", n.name, "|", n.id));
Get((n, c) => c.problems && Print("LAYOUT |", n.id, n.name || n.type, "|", c.problems));
```

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
