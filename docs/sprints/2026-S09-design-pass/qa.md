# QA Pass — Sprint S09

> Mandatory checklist BEFORE writing `retro.md` and closing the sprint.
> If an item isn't met → either document why in `retro.md`, or the sprint does NOT close.

---

## Goal & scope

- [ ] **Sprint goal achieved** (or document gap in retro)
- [ ] **All `main` scope issues** are closed or documented
- [ ] **Parallel issues** closed or explicitly deferred
- [ ] **Unclosed issues**: decided case by case (move to backlog or reassign to next sprint)

## Code health

- [ ] `bundle exec rspec` green
- [ ] `bin/rubocop` no offenses
- [ ] `bin/brakeman` no new warnings (vs previous baseline)
- [ ] `bin/bundler-audit` no vulnerabilities
- [ ] CI on GitHub Actions green
- [ ] Working tree clean, no forgotten commits

## Vision compliance

- [ ] **Manual audit of new copy** in views — no ADR-001 violations (descriptive, not prescriptive language)
- [ ] **Manual scope audit** — no new features violate non-goals (fiscal, public audience, recommendations)
- [ ] **JTBD mapping** — every finished feature/refactor maps to a canonical JTBD (or has an ADR justifying it)
- [ ] **Each issue's discovery card** was fulfilled: DoD checklist complete

## Documentation

- [ ] **New ADR** written if there was a significant architectural decision
- [ ] **Vision update** if audience/scope changed (rare, requires conversation)
- [ ] **Design docs** updated if applicable (brand, tokens, components)
- [ ] **Screenshots regenerated** in `docs/screenshots/` if there were visual changes
- [ ] **CLAUDE.md / IDENTITY.md / memory** updated if working method changed

## GitHub hygiene

- [ ] **Closed issues** have `Done` status in Project board
- [ ] **Milestone ready to close** (all issues in terminal state)
- [ ] **No orphan issues** in the sprint without a status

## Usage metric (post-close verification)

For each JTBD touched in this sprint, document:

| JTBD | Expected metric | State |
|---|---|---|
| #N — ... | "Adrian uses X ≥ N times/week" | ✅ verified / ⚠️ pending / ❌ not yet applicable |

---

## Additional notes

<!-- Anything that doesn't fit above. -->
