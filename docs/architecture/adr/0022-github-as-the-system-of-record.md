# ADR-022 — GitHub is the system of record for outstanding work

- **Status:** Accepted
- **Date:** 2026-08-29
- **Author:** Adrian Castillo
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [`docs/ops/github-workflow.md`](../../ops/github-workflow.md), `design/DECISIONS.md` D53

---

## Context

**This is the second attempt, and saying so is the point.** GitHub was adopted deliberately in
Sprint 1 on 2026-05-14: a private Project v2 (#6, *Stockerly v2 Roadmap*), three issue templates
enforcing the discovery card, a 24-label taxonomy, milestones per sprint, and a 231-line
operational manual at `docs/ops/github-workflow.md` describing all of it. None of that was missing.
By 2026-08-29 the Project was **closed**, the manual described a practice nobody followed, and the
work had migrated, one document at a time, into the design folder — **nine markdown files across
three directories**, each with its own ID scheme:

| Where | What it tracked |
|---|---|
| `design/V2_REMAINING.md` | 74 findings — `X*`, `KIT-*`, `AUTH-*`, `ONB-*`, `CKP-*`, `ACT-*`, `ALR-*`, `AJU-*`, `DSC-*`, `TD*` |
| `design/DECISIONS.md` | 72 decisions, `D1`–`D72` |
| `design/CODE_CHANGES.md` | the execution record and its work orders |
| `design/ui-kit.CHANGELOG.md` | kit versions and open gaps |
| `redesign/OPEN-QUESTIONS.md` | `Q0`–`Q15` |
| `redesign/MARKET_DATA_ENGINE_REMAINING.md` | engine phases A–E |
| `redesign/NEXT-SESSION.md` | a session handoff, frozen 2026-08-24 |
| `docs/research/market-data-providers-2026-08.md` §6 | external verifications owed |
| GitHub Issues | 7 open, of 431 created |

**Of the 39 open findings, 4 had an issue.** In the other direction, #428 exists in GitHub and in no
markdown file. Both sources had drifted, in both directions, at once.

### Why the documents stopped working

Not because they were badly written. The findings are the best artifact this project produced —
every one carries `file:line` evidence, and several record that *the finding was wrong, not the
code* (`X12`, `X13`, `X15`). That quality is the reason the documents survive this decision.

They failed at **tracking**, and the failures are mechanical:

- **A hand-kept count cannot stay right.** The `DECISIONS.md` header was wrong **seven times**,
  every time because a column was carried forward instead of re-derived. It retired its own tally
  on 2026-08-29 and printed the parse command instead.
- **The tally blocked parallel work.** On 2026-08-29 it conflicted in three consecutive pull
  requests, because every concurrent branch had to touch the same block. A board that serializes
  the work it tracks is worse than no board.
- **Derived lists rot the same way.** `V2_REMAINING`'s *Decisions owed* table lists five open
  decisions; parsing the verdict column returns four, and a different four — `D64` is open and
  absent from the table, `D55` and `D57` are resolved and still in it. That is the eighth instance
  of the same defect, in the file that documents the defect.
- **Cross-references go stale silently.** The same file's dependency-ordered build list carries
  `#176` as outstanding. `#176` closed months ago.

`D53` diagnosed this shape — *"the record is written when a decision is taken and not re-read when
reality moves"* — and shipped two of its three fixes. The third, scripting the recount, was never
built. This ADR is the structural answer the third fix was a patch for.

### What the practice actually became

Execution had already left issues. `#366`, `#367`, `#417`, `#418`, `#438`, `#444`–`#448` are pull
requests with no issue behind them. The working loop was *finding in markdown → PR → strike the
finding by hand*. The tracking layer was doing no work that the PR was not already doing, while
costing a merge conflict per concurrent branch.

### Why the first attempt failed

Not for lack of infrastructure, and not only for lack of discipline. The protocol that was
abandoned asked, per sprint, for: a milestone with a one-sentence goal, a `GOAL.md` under
`docs/sprints/<n>/`, a hard cap of seven issues in progress, a five-point QA checklist before
close, a written retro, and a rule that no sprint opens while another is open. For a solo project
worked in evenings and weekends, that is a second job attached to the first.

**What survived is the evidence for which half was too heavy.** Issues kept being created — 431 of
them. Pull requests kept referencing work. What stopped was every ceremony *around* them:
`docs/sprints/` was deleted, the retros were judged disposable and deleted with it, the milestones
stopped being opened, and the board was closed. The tracking did not move to markdown because
markdown was better; it moved there because markdown asked for nothing.

So the diagnosis is two-sided, and taking only one side is how this repeats:

- **The ceremony was disproportionate to the work**, and it is cut here — no sprints, no
  in-progress cap, no close checklist, no retro requirement. The manual that replaces the old one
  is smaller than it, deliberately.
- **The remaining flow has to actually be followed.** A board is worth nothing if items are worked
  without being on it, which is exactly what the last eight months looked like.

## Decision

**GitHub is the single system of record for outstanding work. The private Project (#6, reopened and
renamed `Stockerly`) is the board; issues are the unit of work; the markdown documents keep
reasoning and history and stop tracking state. The sprint ceremony is not restored.**

Three consequences follow directly:

1. **Nothing that is "still to do" lives in a versioned markdown file.** An item's state — open,
   blocked, in progress, done — is read from GitHub and nowhere else. No file restates a count, a
   status, or a list of what is open.
2. **The private Project holds what is not ready to be public.** Draft items carry ideas and
   uninvestigated findings; they have no issue number and are invisible outside the board. An item
   becomes an issue when it can state the four filters ([`docs/ops/github-workflow.md`](../../ops/github-workflow.md)).
   The repo stays public; the board does not.
3. **The markdown documents become the reasoning layer.** `DECISIONS.md` keeps the `Dn` registry
   the `.pen` briefs cite by number; `CODE_CHANGES.md` keeps the execution record;
   `V2_REMAINING.md` keeps how the migration was measured and the post-mortems of the findings
   that turned out to be wrong. Their *inventory* of open work moves out.

**Sprints are not revived.** `docs/sprints/` has not existed for months while `docs/README.md`
pointed at it, and the sprint protocol — milestone, `GOAL.md`, QA pass, retro — was abandoned in
practice well before that. The board's columns are the only cadence. Milestones are available for a
genuine, dated goal and are not created by default.

## Consequences

**What improves.** Concurrent branches stop conflicting over a shared tally. Every count is a query
against GitHub rather than a number someone maintained. Work that is not ready to be public has a
home that is not a gitignored file. `Closes #N` starts closing things again, because the things
have numbers.

**What this costs.** The findings' bodies have to survive the move — a two-line board item where a
`file:line`-evidenced finding used to be would trade the project's best artifact for tidiness. The
migration carries each body in full, and the ⚪ hygiene items that are genuinely one sitting at the
Pencil canvas are grouped into a single issue rather than becoming eight that never move.

**What is deliberately accepted.** Drafts cannot be closed by a pull request — they have no number
— so anything heading for a PR must be promoted to an issue first. That is a constraint, and it is
the one that keeps drafts from quietly becoming a second board.

**The failure mode to watch, and it has a precedent.** This ADR replaces nine documents with a board
and one rewritten manual. The first attempt died by growing a protocol nobody could sustain; the
second dies the same way if the manual grows back. It is 171 lines against the 231 it replaces, and
that direction is the invariant — if a third document is needed to explain the board, or the manual
starts growing, the board is wrong and this decision gets revisited rather than papered over.

**The honest risk.** Nothing here makes the flow self-enforcing. There is no hook, no CI check, and
no gate that fails when an item is worked without being on the board. This decision rests on the
flow being small enough to keep, which is an argument, not a guarantee.
