# Design — Pencil workflow

Everything about Stockerly's design lives here. Read this before touching a `.pen`. It doubles
as context for AI agents.

> **The redesign landed. D8 is retired ([D78](DECISIONS.md), 2026-09-05).** Stockerly pivoted
> 2026-08-20 ([ADR-0010](../docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md))
> to a self-hosted single-user "decision cockpit", and for that revamp this `design/` ran **ahead of
> the code**. It no longer does: all twenty sections of the work order that landed it shipped, the pre-2.0 palette
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

**D78's carve-out, and what it produced.** Three screens were drawn and unbuilt when D8 was
retired, and the rule change deliberately did not decide them — each got its own verdict instead:
`Movimientos` was **built** (D79, `/signals`), `Confluencia` was **demoted to the block it already
was** (D80, then retired outright by D84), and the empty state's demo door was **withdrawn** (C-3)
once its CSV sibling turned out to have shipped. That is the carve-out working: a blind mirror rule
would have deleted all three, including one D42 had explicitly un-gated.

## What's here

_Listing verified against the directory 2026-08-27._

| Path | What it is |
|---|---|
| `ui-kit.lib.pen` | **The design library** — tokens (our `@theme` contract) + components. Read the version from its `kit-version` variable, never from this row |
| `ui-kit.CHANGELOG.md` | Kit versions and what each bump changed, plus the live **Open kit gaps** list |
| `flows/*.pen` | **One file per domain** — seven of them today (`auth`, `onboarding`, `cockpit`, `assets`, `alerts`, `settings`, `discover`) |
| `brand.pen` | The identity sheet (D44/D45) — sheets, not `[Flow] / Screen / State` artboards. Not a flow, which is why it has its own file and its own export section. **On kit 0.9.0 since 2026-08-27** |
| `brand/` | The exported identity assets the repo consumes: `glyph.svg`, `wordmark.svg`, `wordmark.png` |
| `_playground.pen` | Experiments — inside the system (kit installed at 0.8.0 on 2026-08-27; holds `Panel · V1…V4`, the login brand-panel exploration) |
| `DECISIONS.md` | The numbered findings/decisions registry the `.pen` briefs cite |
| `CHECKLIST.md` | What to run, in order, every time a `.pen` is opened for real work |
| `exports/` | Canvas PNGs for review — **committed** (they must travel) |
| `references/` | Local-only device captures — **never commit: real data** (gitignored) |

`CODE_CHANGES.md` (the work order that landed the redesign) and `V2_REMAINING.md` (its punch list
and post-mortems) were retired on 2026-09-16 with nothing left open in either — ADR-022's
amendment. Read them with `git show 120600bb:design/CODE_CHANGES.md`; their finding IDs
(`CKP-1`, `X13`, …) live on in the board's `Finding ID` field.

## Flows

One `.pen` per domain, derived from the app's routes (`config/routes.rb`), not invented. Each flow
**mirrors the screens that exist in code** (D78). A flow earns its own file at ~3+ screens; smaller
ones may merge into a neighbor.

> **The kit 0.8.0 → 0.9.0 migration closed 2026-08-27.** All ten `.pen` files are on the kit —
> `ui-kit`, `alerts`, `settings`, `onboarding` and `brand` at **0.9.0**, the rest at **0.8.1**. The
> split is not drift: 0.8.1 was a token-and-treatment patch every consumer took, 0.9.0 added
> `HeaderBar` and moved only the flows that vendor it. Divergence is zero, verified by comparing
> **values**, not names. `MIGRATION.md` tracked that work and was deleted on close, per its own
> first line — the durable parts are here, in `ui-kit.CHANGELOG.md`'s gap list, and in D53/D57/D58/D59.

> **Status below is the `.pen` file's, not the ERB's.** How closely the code matches a flow is
> measured, never recorded — see *Measuring design against code*. No running count lives here: every
> hand-kept count this folder ever carried went stale.

> **Vocabulary renamed 2026-08-27 (D48).** The tier ladder is now **Holdings** (was Poseo),
> **Watchlist** (was Sigo) and **Tracked** (was Rastreados), and the observation sense of
> *movimiento* is **Señales** — *movimiento* alone means a trade. The es-MX copy shipped in #364.
> **Migration is per-`.pen`, and the table below says where each file stands** — a row still
> reading `sigo` / `rastreados` has not been migrated yet. `assets.pen` is done; the other six are
> not.
>
> Adrian extended the rename to the segmented control itself, so the first tab reads **Holdings**.
> The code caught up the same day — the design leads the
> code on nothing here now. **Lowercase `cartera` in prose is not the tier**; it means the portfolio
> and stays.

| File | Domain | Screens (from code) | Status |
|---|---|---|---|
| `flows/auth.pen` | Auth | login (default · error), 2FA, código de recuperación, forgot, email sent, reset, enlace expirado, contraseña actualizada (+ Login desktop); TOTP · alta and códigos de recuperación, which render in the app shell — no signup (account created in onboarding) | **kit 1.0.0 · mirrors the code** — through `CHECKLIST.md` on 2026-09-16 |
| `flows/onboarding.pen` | Onboarding | setup, integrations, assets, **seguridad**, complete, welcome (+ Setup/Integrations/Assets/Welcome desktop) | **done · in review** — **migrated to kit 0.9.0 on 2026-08-27**: D52's fourth step drawn and the Stepper moved 3 → 4, VOO/CETES split to catch up to the locale's five categories, the stale auth-coherence flag retired |
| `flows/cockpit.pen` | Cockpit (daily driver) | panorama (default · tranquilo · primera vez), señales (default · vacío), asset detail (análisis · aviso TradingView · mi posición · CETES), consolidado (default · sin historial) (+ Panorama/Consolidado desktop) | **kit 1.0.0 · mirrors the code** — through `CHECKLIST.md` on 2026-09-16 |
| `flows/assets.pen` | Activos — the three-tier ladder (D9) + data intake | holdings (default · vacía · sin consolidar), watchlist (default · vacía), registrar movimiento (sheet · con teclado · CETES), historial (default · vacío), tracked (default · agregar activo · sin fuente · sin coincidencias), importar CSV (default · revisión · símbolos desconocidos) + Holdings/Registrar/Tracked desktop | **kit 1.0.0 · mirrors the code** — through `CHECKLIST.md` on 2026-09-16 |
| `flows/alerts.pen` | Reglas y avisos (rules + the notification inbox, D13) | reglas (vacío · default), nueva regla (sheet · calendario), bandeja (default · vacía) | **kit 1.0.0 · mirrors the code** — through `CHECKLIST.md` on 2026-09-16 |
| `flows/settings.pen` | Ajustes — one hub, no admin zone (D5) | hub, integraciones (+ estados), registros, estado y mantenimiento | **done · in review** — **migrated to kit 0.9.0 on 2026-08-27**: `HeaderBar` promoted from four hand-built copies, the BottomNav's double active state fixed, the `Trabajos` badge dropped against §8's documented reason, D52's `Seguridad` row added |
| `flows/discover.pen` | Descubrir — the world, not the instance (D31) | olas (default · todas las canastas · sin datos · calendario agotado) — no desktop artboard, the page reflows | **kit 1.0.0 · mirrors the code** — through `CHECKLIST.md` on 2026-09-16 |

Working model per flow: **(1)** read the existing screens/copy from code (source of truth for
structure + strings) · **(2)** compose them in the `.pen` with the new ui-kit · **(3)** review/feel ·
**(4)** where the two disagree, amend the artboard — or, when the code is what should change, log a
`D<n>` and a board item.

### Desktop pass (2026-08-24, kit 0.5.0 — counts re-checked 2026-08-27)

Every flow has been through it. D4 still governs **which** screens get an artboard: one is drawn
only where the layout genuinely diverges, and the rest reflow — so **13 desktop artboards cover
five of the seven flows**, not 30. `alerts` and `discover` draw none, which is why the table has
seven rows and five of them are non-empty. Counted against `design/exports/*-desktop.png`, which holds those 13
plus the kit's own `ui-kit-shell-desktop`.

| Flow | Desktop artboards | Not drawn, because |
|---|---|---|
| `auth` | Login | Same split-panel as Setup — the two doors match. The other four keep the centered card |
| `onboarding` | Setup · Integrations · Assets · Welcome | Complete inherits the wizard frame exactly |
| `cockpit` | Panorama · Consolidado | The asset detail reflows into one column |
| `assets` | Holdings · Registrar movimiento · Tracked | Watchlist, Holdings vacía and the search states reuse patterns above |
| `alerts` | — | Its list and sheet are the patterns Cartera and Registrar movimiento settle |
| `settings` | Hub · Integraciones · Estado | Registros reflows; a real log table is a new component, so a decision |
| `discover` | — | The page is one column at every width |

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

## Measuring design against code

What the retired audit files taught, kept because each one cost a wrong number.

- **Tokens, in the code:** `bin/checks design-tokens` catches colour literals in views, helpers and
  Stimulus controllers, and `script/checks/baseline.yml` lists what is still tolerated. The retired
  audit scanned `app/views` alone and called the palette gone while the typeahead controller still
  painted it.
- **Tokens, across `.pen` files:** compare the sorted `name=value` list, not the names. Membership
  and equality are two checks.
- **Kit → code:** cross each component against all of `app/views`, not only `components/` — `NavRow`
  is `settings/_nav_row`, `MarketCard` is `dashboard/_sentiment_card`. Count render sites with
  `grep -rc "components/<name>" app lib spec`.
- **Defect or decision:** a screen off the contract *with* an artboard is unfinished work; one
  *without* is either deliberate or a surface nobody drew, and drawing it is design, not a fix.
- **Counting lines:** `grep -c` counts matching lines, not matches — a pass that counts the other way
  reads a regression that is not there. Use `\b(slate|gray)-`, not `slate-`, which matches inside
  `translate-`.

| Kit component | In code |
|---|---|
| `TopBar` · `BottomNav` · `SidebarNav` · `TopBarDesktop` · `HeaderBar` | `components/_<name>` |
| `AppShellDesktop` | composed in `layouts/app`, not a partial |
| `AssetRow` | `components/_asset_row`; its Watchlist sibling is `components/_watch_row`, which the kit lacks |
| `Segmented` · `Segmented3` | one N-ary `components/_segmented` — the two masters are Pencil's limit, not a split to mirror |
| `MovementItem` | `trades/_trade_row` and `dashboard/_signal_row` |
| `MarketCard` · `NavRow` · `SwitchRow` · `Stepper` | `dashboard/_sentiment_card` · `settings/_nav_row` · `settings/_notification_switches` · `onboarding/_step_header` |
| `Card` · `ButtonPrimary`/`Secondary` · `Field` | helpers, not partials: `card_classes` (D75), `button_classes` and `field_classes` (D86) |
| `Logo` · `LogoMark` | `shared/_logo` · `shared/_logo_mark` |

**`HeaderBar`'s `Accion` slot has no code on purpose.** The two screens that draw an action
(Registros, Bandeja) already carry it in the body, and the bar is `lg:hidden` — moving the control
into it would delete it on desktop. The slot ships when a screen needs an action its body has no
home for.

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
