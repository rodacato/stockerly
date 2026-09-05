# GitHub Workflow — Stockerly

> Operational manual for how work is tracked. **GitHub is the system of record**
> ([ADR-022](../architecture/adr/0022-github-as-the-system-of-record.md)) — no markdown file
> states what is open. Required reading before opening an issue or PR.
>
> **Rewritten 2026-08-29.** The version this replaces described a sprint protocol — milestones,
> a 7-in-progress cap, a close checklist, retros — that was abandoned in practice, and a board
> that was closed. The tracking moved into `design/*.md` instead. This is the second attempt, and
> it is deliberately smaller: **the ceremony is what collapsed, not the board.**

---

## Structure

| Element | Where |
|---|---|
| **All outstanding work, and its state** | the private `Stockerly` Project (v2) |
| **Ideas and un-investigated findings** | **draft items** in that Project — no number, not public |
| **Work ready to build** | GitHub Issues, public |
| **Issue taxonomy** | labels (type, context, priority) |
| **Templates** | `.github/ISSUE_TEMPLATE/*.yml`, `.github/PULL_REQUEST_TEMPLATE.md` |
| **Reasoning, decisions, history** | `docs/` and `design/` — never issue state |

**Milestones are not sprints.** They are available for a genuine dated goal and are not created by
default. `docs/sprints/` was retired on 2026-08-28; its commit-prefix taxonomy moved to
[`CONTRIBUTING.md`](../../CONTRIBUTING.md). Retros were deleted at the pivot. If the practice ever
resumes it needs a home decided on purpose.

---

## The loop

```
idea / finding
      │
      ▼
  ┌─────────┐   can it state the 4 filters?
  │  Draft  │──── no ──►  Researching ──┐
  └─────────┘                           │ answered
      │ yes                             │
      ▼                                 ▼
   Issue  ◄──────────────────────────────
      │   promoted from the draft — board position and fields survive
      ▼
  branch ──► PR "Closes #N" ──► Done
```

**Draft** — lives only in the Project. No number, no URL, invisible outside the board. Where an
idea goes the moment it exists, and where a finding goes when it is real but un-investigated. It
costs nothing and notifies nobody; the alternative is an idea that lives in a chat log.

**Issue** — public and numbered. Promoted when it can state the four filters. **Without all four it
stays a draft.** That gate predates this process and does not change.

**Done** — closed by a PR carrying `Closes #N`. Drafts have no number and cannot be closed that
way, so anything heading for a PR is promoted first. This is the constraint that keeps drafts from
quietly becoming a second board.

---

## The board

- **Name:** `Stockerly` · **Owner:** `rodacato` (user-scoped) · **Visibility:** private
- Private means *the board* is private. The repo is public and so is every issue on it. Only
  drafts and the field values below are unlisted.

| Field | Values |
|---|---|
| **Status** | `Draft` · `Researching` · `Ready` · `In progress` · `Blocked` · `Done` |
| **Severidad** | 🔴 the 2.0 is not done while this stands · 🟡 a real gap inside a working screen · ⚪ debt or hygiene |
| **Flow** | `Auth` `Onboarding` `Cockpit` `Activos` `Alerts` `Ajustes` `Descubrir` `Kit` `Cross-cutting` `Tech debt` `Market data` |
| **Finding ID** | the `design/V2_REMAINING.md` ID (`CKP-1`, `ACT-4`, …) where one exists, so a `.pen` brief citing it still resolves |

`Severidad` and `Flow` are the design audit's own scales, carried over deliberately — they were
already the axes the work was organized along.

---

## Labels

Labels are for **search and filtering**, never for state. The Status column owns state.

- **Type:** `feat` · `bug` · `chore` · `docs` · `refactor` · `research`
- **Context:** `ctx:trading` · `ctx:market-data` · `ctx:alerts` · `ctx:identity` · `ctx:notifications` · `ctx:admin`
- **Priority:** `P0` breaks a core JTBD · `P1` before new features · `P2` polish
- **Special:** `design` — design / visual / UX work

**Retired:** `triage`, `discovery-needed` and `ready` are replaced by the `Draft`, `Researching`
and `Ready` columns — a label that duplicates a column is the duplication this process removes.
`parallel` went with the sprint protocol. `beta-blocker` has meant nothing since ADR-010; use `P0`.

---

## How to open work

**An idea, or a finding you have not investigated** → a draft on the board. Title, a body with
whatever evidence you have, `Severidad` and `Flow`. That is the whole ritual.

**Feature / Refactor / Chore / Docs** → the *Feature* template, which enforces the four filters:
documented personal trigger (date + situation) · JTBD (*"When X, I want Y, so that Z"*, mapping to
one of the six canonical or justifying a new one) · usage metric · Definition of Done. Add type,
context and priority labels.

**Bug** → the *Bug* template: what happened, what you expected, repro steps. **Never real financial
data** — the repo is public; use synthetic examples.

**Research** → the *Research* template: the open question, why it matters now, the hypothesis, and
**the criterion that closes it**. A research issue that cannot say what would end it is a reading
list, not work. Its output is a decision — an ADR, or a `Dn` in `design/DECISIONS.md` — or a
promoted issue. List the experts to consult from [`docs/research/experts.md`](../research/experts.md).

---

## How to open a PR

1. **`Closes #N` in the PR body**, first sentence. Only `close`/`fix`/`resolve` and their
   conjugations work, only on merge to the default branch. Don't lose the line across a rebase.
2. Fill [the template](../../.github/PULL_REQUEST_TEMPLATE.md): what it does (why before what),
   the linked issue, and the checklist — tests, Rubocop, ADR-001 (no prescriptive language), no
   fiscal additions, no co-author line, discovery card complete for a `feat`, an ADR for an
   architectural refactor.
3. Never push to `master` and never bypass branch protection. Branch with
   `git checkout -b <name> origin/master --no-track`.

---

## Commands

```bash
# The board
gh project item-list  --owner rodacato <N>
gh project item-create --owner rodacato <N> --title "..." --body "..."   # a draft
gh project item-add   --owner rodacato <N> --url <issue-url>

# Issues
gh issue list --state open --label P0
gh issue view 306

# Auth — Project v2 needs the WRITE scope; read:project only reads
gh auth refresh -s project,read:project
```

**`bin/board-check`** reconciles the two and exits non-zero on drift: an open issue missing from
the board, a closed issue left in a live status, **an open issue sitting in `Done`**, or one of the
built-in workflows that keeps those true having been switched off. The `Done` case is the one with
no workflow behind it, so it is the one that drifts in silence.

```bash
bin/board-check
```

Run it when you want to trust a count, and after any batch of merges. It is **not wired to CI** —
that would need a PAT with `read:project`, since Actions' `GITHUB_TOKEN` cannot read a user-scoped
private Project. ADR-022's honest risk therefore still stands: nothing here is self-enforcing, and
this script only shortens the distance between drifting and noticing.

Required scopes: `repo`, `workflow`, `read:org`, `gist`, `project`, `read:project`.

---

## Common mistakes

1. **Writing what is open into a markdown file.** The defect ADR-022 exists to end. Every count
   kept by hand in this repo has been wrong; the `DECISIONS.md` tally was wrong seven times before
   it was retired. If you want a number, query GitHub.
2. **Promoting a draft that cannot state the four filters.** It stays a draft. That is not a
   holding pen for work you have decided to do anyway.
3. **Duplicating a document into an issue.** Architecture goes in an ADR, design reasoning in
   `design/DECISIONS.md`, research in `docs/research/`. The issue links to it.
4. **Sensitive data in a public issue.** No amounts, account numbers, or real screenshots.
5. **A co-author or AI-attribution line** in a commit, issue or PR. See
   [`AGENTS.md`](../../AGENTS.md) — Adrian is the sole author of every artifact here.
6. **A research issue with no closure criterion.** It will never close.
7. **Assuming the board updates itself.** `Item closed` and `Auto-add to project` are Project
   workflows that must be enabled in the UI — there is no API to turn them on, only to read their
   state, which is what `bin/board-check` reads. With `Item closed` off, `Closes #N` closes the
   issue and leaves the board item in a live status; with `Auto-add to project` off, a new issue
   never reaches the board at all.
8. **Reading a card as current.** A card states the world on the day it was written, and nothing
   re-measures it. On 2026-09-05, five in a row had moved before anyone opened them:

   | Card | What it said | What was true |
   |---|---|---|
   | `CKP-2` | gated on a bar count | the gate had been lifted a week earlier |
   | `JTBD #6` | *"no asset has ever held 200 closes"* | 42 assets hold 200+, min 315 |
   | `SWEEP` / `X4` | four briefs disagree with their kit version | `cockpit.pen`'s agrees |
   | `DSC-1` | presents an open choice | `D73` had closed it, in the code's own comment |
   | `audience.md` | *"reviews portfolio weekly"* | 2–3 times a day |

   None was wrong when written. All five were read as current, and one — `JTBD #6`'s — was quoted
   in good faith as the documented trigger for a feature that then shipped on it.

   **Re-measure before working a card, not after.** Where a card names the measurement that would
   settle it, run that first; `CKP-2` said *"re-measure before treating this as blocked or as
   buildable"* and was right. Where it does not, the cheap check is whether the code still says what
   the card says it says.

---

## References

- [ADR-022](../architecture/adr/0022-github-as-the-system-of-record.md) — why GitHub, and why the first attempt failed
- [Vision](../vision/README.md) · [JTBDs](../vision/jobs-to-be-done.md) · [Non-goals](../vision/non-goals.md)
- [ADR-001](../architecture/adr/0001-descriptive-not-prescriptive-language.md) — product language
- [Expert Panel](../research/experts.md) — structured consultations
- [`design/V2_REMAINING.md`](../../design/V2_REMAINING.md) — the migration's measurement record (no longer a board)
- [IDENTITY.md](../../IDENTITY.md) — the AI assistant's role and its 7 anti-patterns
