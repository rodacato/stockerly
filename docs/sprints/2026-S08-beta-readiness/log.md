# Log — Sprint S08 (beta-readiness)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-17 — Sprint opening: 24h-pause rule honored

Sprint S07 closed 2026-05-16 ~19:09 UTC. S08 opens 2026-05-17 — **24h-pause rule honored this transition.** This is the first transition where the rule was respected (S05→S06 and S06→S07 both overrode it). Adrian explicitly chose inter-sprint cleanup (PR #89) over immediate S08 open, and now opens S08 after the pause cleared naturally.

Per S07 retro commitment: "third consecutive override would invalidate the rule". Rule is preserved by honoring it here.

---

## 2026-05-17 — Scope reset based on parallel research findings

Initial S08 scope was Option B "First-amigo full path" — 6 design revamp issues (#95 + #96 + #99 + #90 + #91 + #98). Pure polish on already-existing screens using the Stockerly-2.0 mockup batch.

After reviewing the parallel research surfaced overnight (`.research/SYNTHESIS-content-product.md`), scope was **reset to Camino E — Mix compliance + auth-design**. Reasons:

1. **Pre-beta blockers identified by research** make the original polish-only scope irresponsible: terms + risk-disclosure are *defective* (describe activities Stockerly doesn't perform), privacy is incomplete vs NLFPDPPP DOF-20-mar-2025, Art. 8 consent missing for datos patrimoniales, ARCO procedure undocumented.
2. **Carry-over P0 multi-currency cost-basis bug** would make the dashboard mockup (#90) render mathematically false numbers if implemented as-is. The fix needs to land BEFORE the dashboard implementation.
3. **The auth revamps (#95 + #96)** are still in scope — small (~3h each) AND #96 register naturally integrates the B-03 Art. 8 consent. Co-fix.

Items removed from initial scope:
- #99 password recovery — defer to S09 with rest of design revamps
- #90 dashboard implementation — defer to S09 post-C1 fix
- #91 portfolio implementation — defer to S09
- #98 trades implementation — defer to S09

Items added based on research:
- #102 (B-01) Terms rewrite
- #103 (B-02) Risk Disclosure rewrite
- #104 (B-04+B-05) Privacy update + ARCO procedure
- #105 (C1) Multi-currency cost-basis P0 fix

Final 6 issues: #102, #103, #104, #105, #95, #96.

---

## 2026-05-17 — Audit caught one substantive misdirection in research synthesis

Discovery-card audit (S07 retro carry-over discipline) applied to all 6 issues against current codebase. One finding:

- **Research synthesis claimed C1 bug was in `Trading::UseCases::ExecuteTrade` (hardcoded "USD").** Code inspection revealed: `ExecuteTrade` already captures currency + fx_rate correctly. The **real bug is in `app/jobs/take_snapshots_job.rb`** which sums `position.market_value` cross-currency without conversion. The currency-aware infrastructure (`Portfolio#total_value(currency:)`) already exists — fix is one method call substitution + tests + backfill decision.

This means C1 is **more tractable than originally thought** (~6-8h instead of speculatively 8-12h or more for a full ExecuteTrade rewrite). Updated #105 discovery card to point at correct location.

**Lesson:** the discovery-card audit discipline (S07 retro carry-over #2) earned its keep on day 1 of S08. Keeping it standard.

---

## 2026-05-17 — Theme rename

Original S08 theme was "design-consolidation" (set during 2026-05-16 inter-sprint conversation). With scope reset to Camino E (mix compliance + auth-design), the theme no longer fits — it's mostly **beta-readiness** (blockers + correctness + auth) with some design revamp residual. Renamed to **"beta-readiness"** to match actual content.
