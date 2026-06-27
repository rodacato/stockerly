# GitHub Workflow — Stockerly

> Operational manual for how we use GitHub Issues + Projects + Milestones + Labels.
> Established in Sprint 1 (2026-05-14). Required reading before opening an issue or PR.

---

## Structure

| Element | Where |
|---|---|
| **Backlog items + bugs + research** | GitHub Issues |
| **Sprint board (visual)** | GitHub Project v2 "Stockerly v2 Roadmap" |
| **Sprint name + goal** | GitHub Milestone (one per sprint) |
| **Issue taxonomy** | Labels (type, context, priority, state, special) |
| **Issue creation templates** | `.github/ISSUE_TEMPLATE/*.yml` |
| **PR template** | `.github/PULL_REQUEST_TEMPLATE.md` |
| **Long-form docs** | `docs/` (do NOT duplicate in issues) |

---

## Current setup (2026-05-14)

### Repo

- **URL:** [github.com/rodacato/stockerly](https://github.com/rodacato/stockerly)
- **Visibility:** public
- **Audience:** closed beta with ≤20 friends (we don't accept external PRs until v1.0)
- **CI:** GitHub Actions (test, security, deploy)

### Project v2

- **Name:** `Stockerly v2 Roadmap`
- **Number:** 6
- **Owner:** rodacato (user-scoped, no org)
- **Status field (default):** `Todo` → `In Progress` → `Done` (simple, not customized)
- **Items:** issues are added via `gh project item-add 6 --owner rodacato --url <issue-url>`

> **Note:** the Status field wasn't customized with additional columns (Triage/Ready/In Sprint/In Review). Instead, workflow state is read by combining **labels** (`triage`, `ready`, `blocked`) and **project Status** (`Todo`, `In Progress`, `Done`). Simpler. If a richer board is needed later, customize via UI.

### Milestones (sprints)

| # | Milestone | Sprint goal (summary) |
|---|---|---|
| 1 | `2026-S02-truth-foundation` | P0 multi-currency phase 1 + kill fake landing + Brand Discovery parallel |
| 2 | `2026-S03-jtbd-alignment` | Currency-aware calculators + deprecate LLM + non-JTBD analytics cleanup |
| 3 | `2026-S04-jtbd-gap-fill` | CETES maturity + JTBD #6 "Notable Observations" |
| 4 | `2026-S05-architectural` | ADR-002 + events cleanup + SimpleUseCase |
| 5 | `2026-S06-visual-coherence` | Landing/login with brand v2 + final tokens migration |
| 6 | `2026-S07-beta-prep` | LFPDPPP + invite codes + minimal onboarding |

Full goal for each milestone is in its description on GitHub (visible when opening the milestone).

### Labels (taxonomy)

**Type** (kind of work):
- `feat` — new functionality mapped to a JTBD
- `bug` — defect in existing functionality
- `chore` — maintenance, cleanup, deprecation
- `docs` — documentation-only changes
- `refactor` — internal change without behavior impact
- `research` — open question to investigate before scoping

**Context** (bounded context touched):
- `ctx:trading`, `ctx:market-data`, `ctx:alerts`, `ctx:identity`, `ctx:notifications`, `ctx:admin`

**Priority**:
- `P0` — beta-blocker or breaks core JTBD
- `P1` — cleanup/refactor before new features
- `P2` — quality / polish

**State**:
- `triage` — new, not yet reviewed (default in templates)
- `ready` — discovery complete, ready for a sprint
- `blocked` — waiting on dependency or decision

**Special**:
- `discovery-needed` — missing one or more discovery card fields
- `beta-blocker` — no friends invited until resolved
- `design` — design / visual / UX work
- `parallel` — parallel axis in a sprint whose main goal is different

---

## How to open an issue

### Feature / Refactor / Chore / Docs

1. Go to [New Issue](https://github.com/rodacato/stockerly/issues/new/choose)
2. Select "Feature / Refactor / Chore"
3. Fill the 4 Discovery Card fields:
   1. **Documented personal trigger** (date + specific situation)
   2. **JTBD** ("When X, I want Y, so that Z" — must map to one of the 6 canonical or justify a new one)
   3. **Usage metric**
   4. **Definition of Done** (concrete checklist)
4. If you can't fill all 4 → the issue stays with `discovery-needed` and `triage`
5. Apply type, context, and priority labels
6. Assign milestone if you already know which sprint it belongs to

### Bug

1. Select "Bug" template
2. Describe what happened, what you expected, repro steps
3. **Do NOT include real financial data** (amounts, positions, account IDs) — use synthetic examples
4. Apply `bug` + `ctx:*` + severity labels

### Research

1. Select "Research" template
2. State the open question, why it matters, hypothesis, closure criterion
3. List experts from the panel to consult (in `docs/research/experts.md`)
4. Expected output: ADR + possible subsequent feature issue

---

## How to open a PR

1. Reference an issue: in commit or PR body use `Fixes #N` (auto-close on merge)
2. Fill the PR template (`.github/PULL_REQUEST_TEMPLATE.md`):
   - What the PR does (1-3 sentences, why before what)
   - Linked issue
   - Mandatory checklist:
     - Tests pass
     - Rubocop clean
     - ADR-001: no prescriptive language
     - Vision: no fiscal additions
     - No co-author in commits
     - Discovery card complete (if feat)
     - ADR exists (if architectural refactor)
3. Commits without `Co-Authored-By` or AI mention

---

## Sprint protocol

### Planning

1. Read issues with label `ready` that don't have a milestone assigned
2. Read the next milestone's goal (`gh api repos/rodacato/stockerly/milestones`)
3. Move issues to the milestone — maximum 7 simultaneous `In Progress` (hard rule)
4. Define **1-sentence goal** in the milestone description (if not already there)
5. If an issue has `parallel` label, it's OK for the milestone to have a different main goal — parallel items take at most 30% of effort

### Execution

1. Each commit references the sprint (e.g., `feat(trading): capture FX at execution [#27]`)
2. Move issue from `Todo` → `In Progress` in Project board when starting it
3. PR links the issue with `Fixes #N`
4. Move to `Done` on merge

### Close

**Before marking sprint as closed:**

- [ ] Milestone goal achieved or documented why not
- [ ] CI green (`bundle exec rspec`, `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`)
- [ ] No new copy violates ADR-001 (manual audit)
- [ ] No new features violate non-goals (manual audit)
- [ ] Sprint retro written in `docs/sprints/<sprint-name>/retro.md`
- [ ] Retro answers: what worked / what didn't / what to change / which of the 6 alignment axes improved?
- [ ] Closed issues have status `Done` in the project

**Hard rule:** no new sprint opens while the previous one is open. If issues remain unclosed at the end, decide:
- Move to backlog (no milestone) if no longer urgent
- Re-assign to the next milestone if still alive

---

## Useful commands (`gh` CLI)

```bash
# List open issues by milestone
gh issue list --milestone "2026-S02-truth-foundation"

# List issues by label
gh issue list --label "P0"

# View a full issue
gh issue view 27

# List milestones
gh api repos/rodacato/stockerly/milestones --jq '.[] | "[\(.number)] \(.title)"'

# List project items
gh project item-list 6 --owner rodacato

# Add an issue to the project
gh project item-add 6 --owner rodacato --url https://github.com/rodacato/stockerly/issues/N
```

---

## Common mistakes to avoid

1. **Creating an issue without a complete discovery card** → stays in `triage` with `discovery-needed`. Doesn't advance to `ready` until completed. Not worked on.
2. **Duplicating info between issue and `docs/`** → docs are for evergreen (vision, ADR, design system, research notes); issues are for state-ful work. If the issue describes architecture, link to the ADR, don't copy it.
3. **Issues with sensitive info** → repo is public. Do NOT include amounts, account numbers, real personal data screenshots. Use synthetic examples.
4. **Co-author in commits** → forbidden by project convention (memory file `feedback_no_coauthor.md`).
5. **Opening a new sprint with the previous one open** → don't do it.
6. **Skipping QA before closing a sprint** → don't do it. The most common trap is "tests pass, ship it" without manually validating ADR-001 / non-goals.

---

## How to refresh `gh` auth (if Project v2 doesn't work)

```bash
gh auth refresh -s project,read:project
```

Currently required scopes: `repo`, `workflow`, `read:org`, `gist`, `project`, `read:project`.

---

## References

- [Vision](../vision/README.md) — north star and 3 hard rules
- [JTBDs](../vision/jobs-to-be-done.md) — the 6 canonical
- [Non-goals](../vision/non-goals.md) — what we are NOT
- [ADR-001](../architecture/adr/0001-descriptive-not-prescriptive-language.md) — product language
- [Code Audit 2026-05](../research/code-audit-2026-05/README.md) — initial backlog input
- [Expert Panel](../research/experts.md) — structured consultations
- [Working method memory](../../.kwik-e/memory/project_working_method.md) — AI assistant's persistent version
