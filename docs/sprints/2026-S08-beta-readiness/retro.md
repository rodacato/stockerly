# Retro — Sprint S08

> Honest post-mortem. Without retro, the sprint does NOT close (hard rule of the protocol).
>
> **Close date:** 2026-05-19
> **Actual duration:** 3 days (vs estimated: ~1 week)
> **Goal:** Close the pre-beta blockers surfaced by research (terms + risk + privacy + ARCO + Art. 8 consent + cost-basis P0) and revamp the auth flow (login + register) so the first invited friend registers on legally sound and mathematically truthful foundations.

---

## What worked?

- **Discovery-card audit at sprint open** (S07 retro carry-over) caught one substantive misdirection — C1 bug was claimed to be in `ExecuteTrade`, audit found it in `TakeSnapshotsJob`. Saved real work hours by pointing at the actual location before any code was written. Keep as standard sprint-open discipline.
- **Scope reset based on research** — instead of executing the original "Option B polish" scope, the parallel research surfaced 5 pre-beta legal blockers + 1 P0 correctness bug. Re-scoping mid-open (before any commit) cost ~30min and prevented shipping an invite on broken foundations.
- **Closing the i18n recurrence loop with an issue + ADR** — Gemini flagged "use I18n" on 5 of 7 PRs. Instead of arguing per PR, created issue #113 in S09 milestone as the canonical Go/No-Go decision card and referenced ADR-007 (which already formalized the position). Future reviews redirect there.
- **Squash-and-merge with cherry-pick rebases** when conflicts appeared. The `spec/requests/legal_spec.rb` was an add/add conflict between #108, #109, #110. Resolved each time mechanically (concatenate `describe` blocks). The friction was visible but cheap.
- **Honest 3-zone language rule** (chat es / repo en / UI es-MX) was promoted from implicit to explicit. Saves a future contributor from wondering whether hardcoded es-MX strings are a bug or a convention.

## What didn't work?

- **Sequential execution of parallelizable work.** Four PRs (#105, #102, #103, #104) had non-overlapping files and could have been delegated to 4 parallel Agents in worktrees. Cost: ~45min wall-clock on sequential, vs ~15min on parallel + ~5min rebase. Adrian called this out directly. Captured as feedback memory.
- **Almost missed reviewing PR #106** during the Gemini-review pass — I scoped only to #107-#112 because they were the S08 scope issues, but #106 (sprint open docs) also had reviews. Adrian had to flag it. Lesson: when "review all PR comments", literally include every open PR, not just the ones in the sprint scope.
- **Three force-pushes during the #112 rebase** because `.git/rebase-merge` kept persisting between attempts. Lost ~10min on a workflow that should have been clean. Root cause: an aborted interactive rebase left state behind that `--abort` didn't fully clean. Workaround was manual `rm -rf .git/rebase-merge` + cherry-pick. Don't reach for `rebase` reflexively; cherry-pick onto fresh origin/master is faster when the branch is small.
- **First version of contract custom error message was inconsistent** with the rest of the contract — my new rule used es-MX (correct for UI) but the existing rules used English. Reviewer flagged it as inconsistency; the real fix is to move the English ones to es-MX, but that's part of the #113 i18n decision, not this sprint.

## What to change for the next sprint?

- [ ] **At scope.md fill-in, group issues by file-overlap** (parallelize cluster A / sequential cluster B) before starting execution. Default to parallel for cluster A.
- [ ] **PR-review-pass scope = ALL open PRs**, not just the ones in current sprint scope. Add `gh pr list --state open` as the first step.
- [ ] **Pre-flight before any `git rebase`:** check `ls .git/rebase-*` for stale state. If present, `git rebase --abort` AND `rm -rf .git/rebase-merge .git/rebase-apply`.
- [ ] **When a Gemini suggestion repeats across 3+ PRs**, stop applying per-PR and capture the underlying decision as an issue or ADR. Repetition is the signal that the decision is at the wrong scope.

---

## Vision alignment — state of the 6 axes

| # | Axis | Before | After | Notes |
|---|---|---|---|---|
| 1 | Every feature maps to a JTBD | 90% | 92% | Art. 8 consent traceable to "patrimony control" JTBD; ARCO procedure traceable to "data ownership" — both newly explicit. |
| 2 | Zero prescriptive copy in code | 85% | 85% | Not touched this sprint. |
| 3 | Zero aspirational fake copy | 70% | 95% | **Major lift.** Terms + Risk Disclosure no longer declare broker activities Stockerly doesn't perform. Privacy no longer claims "no transferimos a terceros". This was the most visible vision win. |
| 4 | Dashboard arithmetic truthful for MXN+USD | 60% | 95% | C1 fix lands. The pre-fix snapshot job summed cross-currency garbage; now routes through `Portfolio#total_value(currency:)`. Dashboard mockup (#90 implementation in S09) can now sit on truthful math. |
| 5 | Architecture without cross-context leaks | 90% | 90% | Not touched this sprint. |
| 6 | Docs reflect current code | 75% | 90% | ARCO procedure documented operationally; ADR-008 captures domicile disclosure trade-off; #113 captures the i18n deferral; log.md kept current throughout. |

---

## Anti-patterns I committed (if any)

- **AP #2 (sequential when parallel would do).** Already covered above; new memory `feedback_parallelize_when_low_risk.md` formalizes the rule.
- **Did NOT commit:** AP #1 (over-engineering — scope was tight), AP #4 (gratuitous comments — kept minimal), AP #5 (faking work — full RSpec ran green at each PR), AP #6 (premature abstraction — `Stockerly::SUPPORT_EMAIL` introduced only after Gemini flagged the duplication, not preemptively).

---

## Real vs estimated time

| Task / Issue | Estimated | Real | Reason for deviation |
|---|---|---|---|
| #105 (C1) | 6-8h | ~2-3h | Currency-aware infrastructure (`Portfolio#total_value(currency:)`) already existed. Fix was 1 method call + 1 symmetric helper + 1 migration. |
| #102 (Terms) | 4-6h | ~2h | Mechanical rewrite with privacy.html.erb from S07 as template. |
| #103 (Risk Disclosure) | 2-3h | ~1.5h | Same template approach. Only complication was prose phrasing for the spec regex (had to reformulate "no ejecuta órdenes" as a continuous string vs fragmented across `<strong>` tags). |
| #104 (Privacy + ARCO) | 5-7h | ~3h | Privacy update was 9 sections (1 new). ARCO procedure doc was the biggest chunk; legal reference work via Context7 + memory was tight. |
| #95 (Login) | 2-3h | ~2h | Form rewrite trivial; cross-cutting spec update (~16 system specs with English login labels) added an hour. |
| #96 (Register + B-03) | 2-3h | ~3h | B-03 inline added migration + contract rule + use case wiring + controller boolean coercion (the nil → false fold was a subtle bug — `ActiveModel::Type::Boolean.cast(nil)` returns nil, not false). |
| **Subtotal sprint** | **21-32h** | **~13.5h** | **Calibration ~0.5×, matches S07 expectation.** |
| Gemini review pass | unestimated | ~1.5h | 7 PRs triaged, 3 real fixes (#107 specs, #110 email/Art.89/ADR-008, #112 checkbox state), 7 inline replies. |
| Post-merge rebases | unestimated | ~30min | 3 rebases (#108, #109, #112) — `legal_spec.rb` add/add conflicts mostly. |
| **Total sprint** | — | **~15.5h** | — |

---

## Registered decisions (link to ADRs if applicable)

- **ADR-008** ([`docs/architecture/adr/0008-privacy-notice-domicile-disclosure.md`](../../architecture/adr/0008-privacy-notice-domicile-disclosure.md)) — Privacy notice does not publish the responsible party's full domicile inline. Documents the substantive-vs-literal compliance trade-off and the revisit triggers.
- **Informal decision (logged in memory):** Three-zone language rule (chat es / repo en / UI es-MX). Formalized in `feedback_repo_language_english.md`.
- **Informal decision (logged in memory):** Parallelize independent, well-spec'd work in worktrees. Formalized in `feedback_parallelize_when_low_risk.md`.
- **Issue #113** in milestone S09 — Go/No-Go decision card for Rails I18n adoption. Referenced ADR-007 (which already formalized the deferral position).

---

## Issues open at close

None from the sprint scope — all 6 closed via PR `Closes #N` autotrigger.

**New issues created during sprint (not in scope, deferred):**

- **#113** — i18n infrastructure decision card. Moved to S09 milestone as Go/No-Go. Not a regression.

---

## Brutal quote of the sprint

> Sequential execution of 6 parallelizable PRs cost ~45min wall-clock that would have been ~15min in worktrees. The discipline missing wasn't speed — it was trusting the discovery cards enough to delegate.
