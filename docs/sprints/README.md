# Sprints — Stockerly

> Operational sprint protocol, established in Sprint 1 (2026-05-14). Template at [`_template/`](./_template/).

> ## ⚠️ This folder contains a template and nothing else.
>
> The protocol below describes one subfolder per sprint holding GOAL, scope, log, QA and retro.
> **No such subfolder exists today** — but not because the protocol was ignored. It was followed:
> S01 through S09 each got the full set, retro included. Commit `cf54285` (2026-08-23) then deleted
> all nine folders in one sweep, as part of removing pre-pivot documentation.
>
> So the honest state is: a protocol that was practiced for nine sprints, whose entire output was
> judged disposable at the pivot, and whose deletion nobody recorded a reason for. S10 is open and
> has no folder yet.
>
> Two things follow. **The structure diagram below reflects the folder as it is now**, not as the
> protocol assumes. And **whether this folder should exist at all is an open question** — if sprint
> artifacts are deleted at each strategic reset, the retro's value is the session that writes it,
> not the file, and that is worth deciding on purpose rather than by omission. The parts of the
> protocol that are unambiguously live — discovery card, 7-item WIP limit, commit prefixes — also
> live in [`../ops/github-workflow.md`](../ops/github-workflow.md), which is the document to trust
> when the two disagree.

---

## Structure

```
docs/sprints/
├── README.md                  ← This file (protocol)
└── _template/                 ← Template to copy at the start of each sprint
    ├── GOAL.md
    ├── scope.md
    ├── log.md
    ├── qa.md
    └── retro.md
```

As designed, each sprint corresponds to a **GitHub Milestone** of the same name and lives in two
places:
- **GitHub:** Milestone (goal in description), assigned issues, Project board
- **docs/sprints/<n>/:** GOAL.md, scope.md, log.md, qa.md, retro.md (long-form, persistent)

Both halves were kept through S09. Only the GitHub half survives today — the long-form half was
deleted wholesale at the pivot (see the banner), and S10 has not restarted it.

Hard rule: **one source of truth per type, never duplicate.** State-ful work lives in GitHub; long-form (retro, post-mortem, mid-sprint decisions) lives in `docs/sprints/<n>/`.

---

## Protocol

### 1. Opening (1 session, ≤30 min)

1. **Close the previous sprint first.** Hard rule: no new sprint opens while a previous one is still open (without a written retro).
2. **Copy `_template/`** to `docs/sprints/<sprint-name>/` (format `YYYY-S<n>-<theme-kebab>`).
3. **Write the sprint goal** in `GOAL.md` (a single sentence, non-negotiable).
4. **Sync it to the GitHub Milestone description** (don't duplicate — reference).
5. **Select issues with `ready` label** that map to the goal. Assign to milestone via `gh issue edit N --milestone "..."`.
6. **Fill `scope.md`** listing selected issues + brief reason.
7. **Verify constraints:**
   - Max 7 simultaneous `In Progress` issues
   - If there are `parallel`-labeled issues, they must be ≤30% of total estimated effort
   - Each issue has a complete discovery card (no `discovery-needed`)
8. **Move issues to "In Progress" in Project board** as you start working them (not all at once).

### 2. Execution

- **Each commit references the issue:** `feat(trading): capture FX at execution [#27]`
- **Non-trivial notes during execution** → `log.md` (decisions, problems, experts consulted). NOT a daily journal; it's for "what cost me to discover and I'd like to remember".
- **PR links issue with `Fixes #N`** for auto-close on merge
- **If you discover new work** → open a separate issue (don't bloat the current sprint). Decide if it enters this sprint or the next.
- **If an issue gets blocked** → `blocked` label, comment explaining, consider moving it to another milestone.

### 3. Close (1 session, 60-90 min)

#### QA pass (mandatory before closing)

Fill `qa.md` (template copy) and verify:

- [ ] **Milestone goal achieved** (or document gap in retro)
- [ ] **CI green locally:** `bundle exec rspec`, `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`
- [ ] **No new copy violates ADR-001** (manual audit of view diffs)
- [ ] **No new features violate non-goals** (manual scope audit)
- [ ] **Each issue's discovery card was fulfilled** (DoD checklist)
- [ ] **Usage metric** for each affected JTBD: verified or documented as pending to measure
- [ ] **Screenshots regenerated** in `docs/screenshots/` if there were visual changes
- [ ] **Closed issues** have `Done` status in Project board
- [ ] **Documentation updated** if applicable (new ADR, vision update, design.md, etc.)
- [ ] **Working tree clean**, no pending commits

#### Retro

Write `retro.md` following the template. Minimum:
- **What worked?** (replicate)
- **What didn't work?** (correct)
- **What to change for the next sprint?** (concrete action)
- **Which of the 6 alignment axes improved?** Indicate approximate % or state per axis:
  1. Every feature maps to a JTBD
  2. Zero prescriptive copy
  3. Zero aspirational fake copy
  4. Dashboard arithmetic truthful for MXN+USD
  5. Architecture without cross-context leaks
  6. Docs reflect code
- **Real vs estimated time** (calibration for future sprints)
- **Anti-pattern violated, if any** — the 7 are listed in [`IDENTITY.md`](../../IDENTITY.md)

#### Formal close

1. **Close the milestone** in GitHub (`gh api repos/.../milestones/N -X PATCH -f state=closed`)
2. **Unclosed issues** → decide case by case (move to backlog without milestone, or reassign to next sprint)
3. **Commit the retro** with message `retro(<sprint>): close — <one-line takeaway>`
4. **Push to origin**
5. **Anti-pattern guard:** don't open the next sprint in the same session. Take at least 24h pause to process.

---

## Naming conventions

### Sprint folders

`YYYY-S<n>-<theme-kebab>` — examples: `2026-S01-reset`, `2026-S02-truth-foundation`, `2026-S03-jtbd-alignment`

The sprint number is **project-sequential**, not yearly. If the project lasts years, the counter doesn't reset.

### Sprint themes

Each sprint has a short theme (1-3 words) describing the main focus. Visible in the folder name and the milestone title.

### Commit prefixes

- `feat(<ctx>):` — new functionality
- `refactor(<ctx>):` — internal change
- `chore:` — maintenance, cleanup
- `docs:` — documentation only
- `fix:` — bug fix
- `test:` — tests only
- `retro(<sprint>):` — sprint retro commit

No `Co-Authored-By` (project rule).

---

## Hard rules

All six were honored through S09. Rules 4 and 5 are now **unverifiable from the repo**, because the
artifacts that evidenced them were deleted — a different failure from being ignored, and flagged
here rather than quietly dropped.

1. **No new sprint while previous is open.** The previous is closed when its milestone is closed
   (originally: *"and `retro.md` exists"* — see rule 5).
2. **No issue without a discovery card.** Issues with `discovery-needed` are not eligible to enter a sprint.
3. **No more than 7 simultaneous `In Progress` issues.** If the limit is hit, no new ones open; existing ones close.
4. **No skipping QA before close.** The QA pass is not optional, even when "looks easy to close".
   *(No `qa.md` survives in the repo. Its automated half — rspec, rubocop, brakeman, bundler-audit —
   runs on every PR regardless.)*
5. **Retro written or sprint not closed.** *(No `retro.md` survives either. Decide explicitly
   whether retros resume for S10 or the rule is dropped; an unenforceable "hard rule" is the kind of
   aspiration [anti-pattern #7](../../IDENTITY.md) is about.)*
6. **Parallel work max 30% of effort.** If a sprint has more parallel effort than main, it's badly scoped.

---

## References

- [Vision README](../vision/README.md) — the north star
- [JTBDs](../vision/jobs-to-be-done.md) — the 6 canonical
- [GitHub workflow](../ops/github-workflow.md) — manual for using GitHub, and the live half of this protocol
- [IDENTITY.md](../../IDENTITY.md) — the AI assistant's role and the 7 anti-patterns

> Earlier revisions linked `.kwik-e/memory/…` here. Those paths are gitignored private working
> memory that exists on one machine; they resolve for nobody reading this repo, so they are not
> references. Anything a reader needs has to be tracked in `docs/` or at the repo root.
