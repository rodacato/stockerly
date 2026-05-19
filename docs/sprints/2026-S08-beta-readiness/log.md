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

---

## 2026-05-18 — All 6 issues completed in one sitting (sequential)

Walked through the full scope in one session: #105 (C1 fix) → #102 (Terms) → #103 (Risk) → #104 (Privacy + ARCO) → #95 (Login) → #96 (Register + B-03). Each as its own branch + PR, ran the full RSpec suite (2255+ examples) green before pushing. Decisions worth keeping:

- **#105 C1:** added `Portfolio#invested_value(currency:)` symmetric with `total_value`. Removed `default: "USD"` from `portfolio_snapshots.currency` to force explicit declaration. No backfill — closed beta with empty portfolios makes pre-fix snapshots irrelevant. Logged in commit.
- **#102 Terms:** rewrote 8 sections es-MX with CDMX jurisdiction. Also localized the shared `legal.html.erb` layout chrome ("Last Updated" → "Última actualización", "Print" → "Imprimir") — it's used by privacy + terms + risk too.
- **#103 Risk Disclosure:** removed all leverage/margin/liquidation/stop-loss/slippage fiction. Added explicit CNBV non-regulation statement and verify-with-your-broker guidance.
- **#104 Privacy + ARCO:** referenced NLFPDPPP DOF-20-mar-2025, split necesarias/voluntarias (Art. 15), retention policy (Art. 11), remisiones (Arts. 35-36), 20-day ARCO window (Art. 32). New `docs/ops/arco-procedure.md` operational runbook.
- **#95 Login:** localized + cross-cutting update of ~16 system specs that used English form labels. Specs visiting `/register` and `/forgot-password` kept English strings (those views land in #96 and S09 #99).
- **#96 Register + B-03:** added Art. 8 consent checkbox (non-pre-checked), migration for `users.consents_data_processing_at`, contract + use case wired through. Controller coerces nil → false explicitly so unchecked is denial, not "field missing".

---

## 2026-05-18 — Sequential execution was a mistake; parallelizable work captured as memory

Reviewing the dependencies after the fact: **#105, #102, #103, #104 had no overlapping files** (different bounded contexts or different actions/views). They could have been delegated to 4 parallel Agents in worktrees and merged sequentially with trivial conflicts at the end. Sequential cost ~45min wall-clock; parallel would have cost ~15min wall-clock + ~5min conflict resolution.

Adrian flagged this directly: *"se podian trabajar en paralelo?"*. Captured as new feedback memory `feedback_parallelize_when_low_risk.md` with 4 conditions for paralelizable work and 3 anti-signals. **Lesson next sprint:** group issues by file-overlap during scope.md, not by sequential ordering.

---

## 2026-05-18 — Gemini auto-review pass

All 7 PRs (including #106 docs-only) received Gemini auto-reviews. Triage:

- **Recurring suggestion across 5 PRs:** migrate hardcoded es-MX strings to Rails I18n. Decision (formalized with Adrian): defer. ADR-007 already documents the position; created issue #113 in milestone S09 as the canonical Go/No-Go decision card so future reviews can be redirected there instead of re-debated per PR.
- **Three real fixes applied:**
  - #107: consolidated 2 redundant snapshot specs into one (less job invocations).
  - #110: centralized support email in `Stockerly::SUPPORT_EMAIL` (3 hardcodes → 1 constant). Tightened ARCO step 2.3 per Art. 89 Reglamento LFPDPPP (carta poder + 2 witnesses, or notarial instrument).
  - #112 (high severity): checkbox consent state didn't persist on validation rerender. Fixed via `check_box_tag` helper + new spec asserting `checked` after non-consent validation error.
- **One deferred to ADR-008:** Art. 16 Fracción I requires the responsible party's full domicile. Decided not to publish a home address in a public repo; ADR-008 documents the substantive-vs-literal compliance trade-off and the revisit triggers.
- **Reviewer-flagged-but-rejected:**
  - `support@notdefined.dev` is the real project email, not a placeholder.
  - `text-primary` on legal mail links is intentional brand-link color (matches privacy from S07).
  - `legal_controller.rb` Spanish error messages: reviewer's inversion — those messages render in the UI, so es-MX is correct; the OTHER English messages are the actual inconsistency (will move when #113 lands).

---

## 2026-05-19 — Merge order + post-merge cleanup

Merge order chosen by Adrian: #106 → #107 → #110 → #108 → #109 → #111 → #112. Squash-and-merge for all except #110 (kept 3 commits because they were logically distinct: feat + Gemini fix + ADR-008).

Rebases needed after each legal-cluster merge because `spec/requests/legal_spec.rb` was an add/add conflict (all 3 PRs created the file). Resolution each time was mechanical: concatenate `describe` blocks in priority order. #112 also needed a `db/schema.rb` conflict resolved (version line + maintaining both #107 and #112 schema changes).

Final state: 6/6 sprint issues closed via PR `Closes #N` autotrigger. 7/7 PRs merged. Master 1841 → ~2260 specs (added auth specs + legal request specs + register consent spec + ARCO doc spec).
