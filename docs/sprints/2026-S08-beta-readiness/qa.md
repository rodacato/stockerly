# QA Pass — Sprint S08

> Mandatory checklist BEFORE writing `retro.md` and closing the sprint.
> If an item isn't met → either document why in `retro.md`, or the sprint does NOT close.

---

## Goal & scope

- [x] **Sprint goal achieved** — all pre-beta blockers closed (B-01 Terms, B-02 Risk, B-03 Art. 8 consent, B-04 Privacy NLFPDPPP, B-05 ARCO procedure) + C1 cost-basis P0 fixed + auth revamps (#95 login + #96 register) shipped.
- [x] **All `main` scope issues** closed — 6/6 (#102, #103, #104, #105, #95, #96).
- [x] **Parallel issues** — none in this sprint (single-themed).
- [x] **Unclosed issues** — none. One new issue (#113) created mid-sprint for i18n decision, parked in S09 milestone (not a regression, intentional deferral).

## Code health

- [x] `bundle exec rspec` green — **2285 examples, 0 failures**
- [x] `bin/rubocop` no offenses — **822 files inspected, no offenses detected**
- [x] `bin/brakeman` no new warnings — **0 warnings**
- [x] `bin/bundler-audit` no vulnerabilities — **No vulnerabilities found**
- [ ] CI on GitHub Actions green — pending verification after `chore/s08-close` lands (last per-PR CI was green)
- [x] Working tree clean — only `.DS_Store` and `.research/` (both gitignored)

## Vision compliance

- [x] **Manual audit of new copy** — no ADR-001 violations. New legal pages (terms, risk, privacy) are descriptive; ARCO procedure doc is operational/factual; auth revamps reuse existing voice.
- [x] **Manual scope audit** — no non-goal violations. No fiscal copy, no public audience copy, no investment recommendations introduced.
- [x] **JTBD mapping** — every shipped feature maps to a JTBD:
  - Terms/Risk/Privacy → "data ownership + legal validity of registration"
  - Art. 8 consent → "patrimony control"
  - ARCO procedure → "data ownership"
  - C1 cost-basis → "consolidated patrimony in MXN truthful"
  - Login/Register revamps → "auth flow native to MX audience"
- [x] **Discovery card DoD** — every issue's DoD checklist completed.

## Documentation

- [x] **New ADR written** — ADR-008 (privacy notice domicile disclosure trade-off).
- [x] **Vision update** — not applicable (audience/scope unchanged).
- [x] **Design docs** — not applicable (no token/component/brand changes; design implementation deferred to S09).
- [x] **Screenshots regenerated** — not applicable (legal pages are not in the screenshots set; auth pages will be regenerated when S09 visual design pass lands).
- [x] **CLAUDE.md / IDENTITY.md / memory updated** — 3 memory files touched: `feedback_repo_language_english.md` (expanded to 3-zone rule), `feedback_parallelize_when_low_risk.md` (new), `MEMORY.md` (index updated).

## GitHub hygiene

- [x] **Closed issues** — all 6 sprint issues closed via PR `Closes #N` autotrigger.
- [x] **Milestone ready to close** — 6/6 issues in terminal state; closing executed as part of this `chore/s08-close` PR.
- [x] **No orphan issues** — sprint board reviewed; nothing in flight.

## Usage metric (post-close verification)

For each JTBD touched in this sprint:

| JTBD | Expected metric | State |
|---|---|---|
| Legal validity of invite acceptance | "Adrian or invitee can read /terms, /risk-disclosure, /privacy in es-MX with no fictional broker activity claims" | ✅ verified manually |
| Patrimony control (Art. 8 consent) | "Register form requires non-pre-checked checkbox; `users.consents_data_processing_at` is populated on success" | ✅ verified via spec + manual |
| Data ownership (ARCO) | "ARCO procedure documented; 20-day response window declared in /privacy" | ⚠️ pending real ARCO request to exercise the procedure end-to-end (not blocking) |
| Consolidated patrimony in MXN truthful (C1) | "Snapshot job produces MXN-converted total for a mixed MXN+USD portfolio" | ✅ verified via Lucía-invariant spec |
| Auth flow native to MX (login + register es-MX) | "Adrian invites first friend, friend registers in es-MX without English fallback strings" | ⚠️ pending first invite (deferred until Adrian decides timing) |

---

## Additional notes

- 7 PRs merged in S08: #106 (sprint open docs), #107 (C1), #108 (Terms), #109 (Risk), #110 (Privacy+ARCO+ADR), #111 (Login), #112 (Register+B-03).
- One new constant introduced: `Stockerly::SUPPORT_EMAIL` in `config/initializers/stockerly.rb` (centralizes 3+ hardcoded occurrences).
- One new migration: `users.consents_data_processing_at`.
- One schema-default removed: `portfolio_snapshots.currency` no longer defaults to "USD" (must be declared explicitly).
- Test suite grew from ~1841 (S07 close) → 2285 (S08 close), +~24% reflecting new auth specs, legal request specs, ARCO doc specs, and the Art. 8 consent persistence spec.
