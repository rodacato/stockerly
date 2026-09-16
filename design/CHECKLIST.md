# Opening a `.pen` — the checklist

Run it top to bottom whenever a flow is opened for real work. The order matters: the kit comes
first so every later step — layout, screenshots, exports — sees current components.

**This file is the procedure, never the progress.** Which flow has been through it lives on the
board or in your own notes, not here ([ADR-022](../docs/architecture/adr/0022-github-as-the-system-of-record.md)).
Each step points at where its rule is written instead of restating it; when a rule changes, change
it there.

## 0. Before the first write

- [ ] The `.pen` is **open in Pencil**, on the main checkout — never a worktree ([README](README.md#working-a-pen--what-this-migration-paid-to-learn))
- [ ] The identity probe prints the artboard names you expect and a `kit-version-source` ([README](README.md#measure-the-file-before-you-trust-a-document-about-it))
- [ ] Read the brief and the Log once, before trusting either

## 1. Kit

- [ ] `kit-version-source` against `ui-kit.lib.pen`'s `kit-version`; read the [CHANGELOG](ui-kit.CHANGELOG.md) entries in between
- [ ] Tokens re-vendored by **value**, not by name — membership and equality are two checks
- [ ] Components re-vendored; the probe's `LOCAL COPY` rows replaced by instances
- [ ] **Measure before replacing** — a copy that differs may be a deliberate variant, not drift
- [ ] `kit-version-source` updated only if the full sync happened

## 2. Against the code (D78: the code wins)

- [ ] Every artboard crossed with the views behind its route: structure, states, spacing
- [ ] Every string exists in `config/locales/es-MX.yml` — never invent copy
- [ ] Tokens only: zero hex in the flow ([Open kit gaps](ui-kit.CHANGELOG.md#open-kit-gaps) for the one known exception)
- [ ] D48 vocabulary: Holdings · Watchlist · Tracked · Señales
- [ ] A disagreement is fixed **in the artboard**; when the code is what should change, a `D<n>` in [DECISIONS](DECISIONS.md) and a board item
- [ ] Drift found in the code itself goes to the board, not into the brief

## 3. Coverage

- [ ] Every route and state in code has an artboard, or the brief's *States not drawn* says why
- [ ] A screen drawn with no code gets a build-or-retire verdict (D78's carve-out)
- [ ] Desktop artboards only where the layout diverges (D4); mobile ≥ 390×844, desktop ≥ 1280×800 (D7)

## 4. Brief and Log

- [ ] The brief keeps its fixed sections, in this order: **Purpose · Entry points · Screens (left → right) · Business rules · Copy source · States not drawn · Open findings (`D<n>` numbers only) · History (→ Log)**
- [ ] Present tense only — the brief says what is true now
- [ ] Anything dated moves to the **Log** frame; anything explaining *why* becomes a `D<n>` the brief cites
- [ ] Retired references removed or pointed at history: D8 → D78, `CODE_CHANGES` / `V2_REMAINING` → `git show 120600bb:design/<file>`
- [ ] Sections that no longer describe the file are deleted, not annotated

## 5. Canvas

- [ ] **Shared elements on top**: kit components in one row, flow-local components in the row below
- [ ] **One band per journey**, brief first at `grid-x0`, screens in the order a person lives them
- [ ] Log below the brief, overlapping nothing
- [ ] The five `grid-*` variables declared (`grid-x0`, `grid-brief-w`, `grid-gutter` 120, `grid-y0`, `grid-row-gap` 260) and every position computed from them: first screen at `x0 + brief-w + gutter`, each next at `previous.x + previous.width + gutter`
- [ ] Names read `[Flow] / [Screen] / [State]`; screens `clip: true`; no `placeholder` left
- [ ] Layout probe returns no `LAYOUT` rows; a screenshot of the file reads left to right

## 6. Close

- [ ] Changed artboards re-exported to `exports/`, renamed and indexed ([exports README](exports/README.md))
- [ ] Saved in Pencil (no auto-save), and the write verified on disk with a `Get`, not only `git status`
- [ ] The flow's row in [README](README.md#flows) matches the file
- [ ] One commit per step — kit sync, code mirror, brief, layout, exports — so a review can follow it
