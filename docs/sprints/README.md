# Sprints — Stockerly

> Operational sprint protocol. This folder contains **one subfolder per sprint** with GOAL, scope, log, QA, and retro. Template at [`_template/`](./_template/).
>
> Established in Sprint 1 (2026-05-14).

---

## Structure

```
docs/sprints/
├── README.md                  ← This file (protocol)
├── _template/                 ← Template to copy at the start of each sprint
│   ├── GOAL.md
│   ├── scope.md
│   ├── log.md
│   ├── qa.md
│   └── retro.md
├── 2026-S01-reset/            ← Sprint 1 (created retroactively)
│   └── retro.md
├── 2026-S02-truth-foundation/ ← Sprint 2 (to be created at start)
│   └── ...
└── ...
```

Each sprint corresponds to a **GitHub Milestone** of the same name. The sprint lives in two places:
- **GitHub:** Milestone (goal in description), assigned issues, Project board
- **docs/sprints/<n>/:** GOAL.md, scope.md, log.md, qa.md, retro.md (long-form, persistent)

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
- **Anti-pattern violated, if any** (reference `.kwik-e/memory/feedback_anti_patterns.md`)

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

## Hard rules (non-negotiable)

1. **No new sprint while previous is open.** The previous is closed only when `retro.md` exists and the milestone is closed.
2. **No issue without a discovery card.** Issues with `discovery-needed` are not eligible to enter a sprint.
3. **No more than 7 simultaneous `In Progress` issues.** If the limit is hit, no new ones open; existing ones close.
4. **No skipping QA before close.** The QA pass is not optional, even when "looks easy to close".
5. **Retro written or sprint not closed.** Without a retro, you don't advance.
6. **Parallel work max 30% of effort.** If a sprint has more parallel effort than main, it's badly scoped.

---

## References

- [Vision README](../vision/README.md) — the north star
- [JTBDs](../vision/jobs-to-be-done.md) — the 6 canonical
- [Working method memory](../../.kwik-e/memory/project_working_method.md) — AI assistant's version
- [GitHub workflow](../ops/github-workflow.md) — manual for using GitHub
- [Anti-patterns](../../.kwik-e/memory/feedback_anti_patterns.md) — what to avoid
