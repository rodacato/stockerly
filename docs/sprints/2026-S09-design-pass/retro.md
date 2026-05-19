# Retro — Sprint S09

> Honest post-mortem. Without retro, the sprint does NOT close (hard rule of the protocol).
>
> **Close date:** 2026-05-19
> **Actual duration:** 1 day (vs estimated: 1 week)
> **Goal:** Implement the Stockerly-2.0 design pass on the operational screens (dashboard, portfolio, trades, password recovery) so the first invited friend lands on a visually coherent es-MX UI built on top of S08's truthful + legally valid foundations.

---

## What worked?

- **Discovery-card audit at sprint open** (S07 retro carry-over, applied for the third time). Per PR I read the issue body + the actual code at HEAD + the mockup before writing a line. Catches like "the contract already supports `currency` from S08, just wire it through" (#91) and "MAJOR_SYMBOLS array_position sort handles MX-first regardless of insert order" (#92) came from looking before coding.
- **One PR per issue, full Gemini-review loop per PR.** No batching. Each PR got its own audit + fix + reply pass. Some Gemini catches were substantial (HIGH severities on #91 tab/panel mismatch, #98 fractional-shares truncation, #99 `@user` not set on validation failure). Catching them per-PR meant fixing them in their immediate context, not later in a giant cleanup.
- **Cross-repo fixes when a typo turns out to be widespread.** When Gemini caught NLFPDPPP→LFPDPPP in PR #121 (a single occurrence on the surface), I grepped the entire repo and found 26 instances across 9 files. Fixed all of them in the same PR rather than leaving inconsistency to find later. Tech debt that gets exposed should be paid down where it's exposed.
- **Building on S08 constants instead of reintroducing literals.** `Stockerly::SUPPORT_EMAIL` from S08 #110 got reused in /profile data-export links (#97); `Trade::MODIFICATION_WINDOW` introduced in #98 anchored the editable predicate. Constants compound: each one I add becomes the natural reference for the next surface that needs the same value.
- **24h-pause rule override was justified and bounded.** Single override (1 of 3 allowed before invalidation). Not a slide back to the pre-S08 pattern.

## What didn't work?

- **Sequential execution again.** Same anti-pattern as S08. Could have parallelized #92 (market) + #97 (profile) since they touch disjoint files. Justification this time was that Gemini fixes compounded (e.g. the `f.text_field` lesson from PR #121 informs how I'd write future forms) — so isolated parallel agents would each miss the accumulated lessons. Still, that's a defensible exception, not a blanket excuse.
- **Initial S09 sprint open shipped doc templates unfilled (PR #115).** My Write tool calls right after `cp` from `_template/` failed silently with "File has not been read yet" errors and I committed without verifying. Gemini caught it; I fixed in the same PR. The Read-then-Write contract exists to prevent this.
- **NLFPDPPP typo propagated across 26 occurrences before catch.** First use was in S08; I should have looked up the official acronym then instead of relying on intuition ("Nueva LFPDPPP → NLFPDPPP"). Legal acronyms in particular need authoritative-source validation on first use.
- **Pre-existing tech-debt instance vars in partials surfaced as Errors in my IDE only after I touched the files.** I cleaned them up where they fell into scope (positions_table, allocation_sidebar, performance_chart in #91; listings_table in #92), but it's reactive cleanup rather than a deliberate refactor. There's likely more elsewhere that hasn't been flagged because nobody's edited those files yet.

## What to change for the next sprint?

- [ ] **At sprint open, group issues by file-overlap and tentatively mark which ones could parallelize.** Even if I don't end up parallelizing for compound-lesson reasons, the explicit grouping forces the choice instead of defaulting to sequential.
- [ ] **Legal/regulatory acronyms get a Context7 (or external) lookup on first use**, not "from memory". Add a quick reference list in `docs/architecture/legal-acronyms.md` if multiple appear (LFPDPPP, ADR-references to NLFPDPPP, etc.).
- [ ] **Pre-flight `git status` + `git rebase --abort` cleanup before any rebase.** S08 retro flagged this once; S09 didn't hit it again because I was careful, but the discipline should be a routine, not vigilance.
- [ ] **Document the constant-introduction pattern.** `Stockerly::SUPPORT_EMAIL`, `User::PASSWORD_RESET_EXPIRES_IN`, `Trade::MODIFICATION_WINDOW` are all examples of "introduce a constant when a literal appears in ≥2 places". Worth surfacing as a convention in CLAUDE.md so future PRs default to extracting rather than duplicating.

---

## Vision alignment — state of the 6 axes

| # | Axis | Before | After | Notes |
|---|---|---|---|---|
| 1 | Every feature maps to a JTBD | 92% | 94% | Profile's ARCO data-export now traces explicitly to LFPDPPP rights JTBD. Trades editable window codified as `MODIFICATION_WINDOW` reads like a domain decision, not a magic number. |
| 2 | Zero prescriptive copy in code | 85% | 88% | Auth flow + dashboard/portfolio/trades/market/profile copy reviewed. No "Buy now!" or "Don't miss out!" residue. Some pre-Lumen slate classes remain (admin views, news/earnings) but they're scoped to S10+. |
| 3 | Zero aspirational fake copy | 95% | 96% | Stable. No new aspirational claims introduced. |
| 4 | Dashboard arithmetic truthful for MXN+USD | 95% | 97% | Now visible — the C1 fix from S08 #105 renders correctly in the new dashboard KPI strip (#90), in the portfolio positions table per-row (#91), and in the trades summary cards (#98). The math wasn't truthful in spec only anymore; it's truthful on the screen the user actually sees. |
| 5 | Architecture without cross-context leaks | 90% | 90% | Not touched this sprint. |
| 6 | Docs reflect current code | 90% | 93% | S08+S09 NLFPDPPP→LFPDPPP cleanup. CLAUDE.md updated with 3-zone language rule + i18n No-Go. Sprint docs all closed cleanly. |

---

## Anti-patterns I committed (if any)

- **AP #2 (sequential when parallel would do).** Repeated from S08. Justified-ish this time because Gemini lessons compounded across the sequence, but the discipline is still underused. Updated retro action item to force explicit grouping.
- **AP #5 (fake work).** PR #115 shipped sprint doc templates unfilled because I trusted Write tool success without re-reading. Caught by Gemini, fixed in same PR. The Read-then-Write contract is now in muscle memory for this kind of operation.
- **Did NOT commit:** AP #1 (over-engineering — every PR stayed in scope), AP #4 (gratuitous comments — kept minimal), AP #6 (premature abstraction — every constant I introduced had ≥2 callers when introduced).

---

## Real vs estimated time

| Task / Issue | Estimated | Real | Reason for deviation |
|---|---|---|---|
| #90 (Dashboard) | 6-8h | ~3h | Helpers (`format_currency_mx`, `dashboard_greeting`) reused later in #91 and #92. Mockup-to-Tailwind translation was straightforward. |
| #91 (Portfolio) | 5-7h | ~3h | Trade form already had currency-field plumbing from S08 #105; this PR wired the UI. The HIGH-severity tab/panel bug added ~10min of fix + commit. |
| #98 (Trades) | 4-5h | ~2.5h | Summary helper + Trade#editable? + currency-prefix per row. Spec updates were mechanical sed replacements. |
| #99 (Password recovery) | 3-4h | ~2.5h | Two small forms. The `@user` not-set bug in controller required a use case refactor (~30min). Mailer + use case constant cleanup added ~30min. |
| #92 (Market) | 5-7h | ~3.5h | MarketIndex::MAJOR_SYMBOLS array_position sort was a small but careful change. VIX dynamic-class refactor unblocked a real Tailwind JIT issue. Two helpers extracted in fix pass. |
| #97 (Profile) | 4-5h | ~3h | 4-tab layout from scratch. Removed watchlist + 3 partials. Cross-repo NLFPDPPP fix added ~20min. |
| #113 (i18n decision) | 1h | ~30min | Pure documentation; CLAUDE.md update + memory + close issue. |
| **Subtotal sprint** | **28-37h** | **~18h** | **Calibration ~0.55×, slightly higher than S08's 0.5× — Gemini fix loops added per-PR overhead.** |
| Gemini review pass + fixes (across all 7 PRs) | unestimated | ~2h | Average ~15min per PR for triage + apply + reply. |
| Sprint open (S09 #115) | unestimated | ~30min | Including the doc-templates fix-up. |
| **Total sprint** | — | **~20.5h** | — |

Across two consecutive sprints (S08 ~15.5h, S09 ~20.5h) the 0.5× calibration holds. The slight uptick in S09 reflects Gemini-loop overhead, which is worth the cost given the substantive HIGH-severity catches.

---

## Registered decisions (link to ADRs if applicable)

- **No new ADRs.** This sprint's decisions either built on existing ADRs (007 i18n, 008 domicile) or are operational conventions captured in CLAUDE.md + memory:
  - 3-zone language rule (chat es / repo en / UI esMX) formalized in CLAUDE.md.
  - i18n No-Go with explicit re-visit triggers (bilingual goal OR idle capacity) — closes #113.
  - `Trade#editable?` + `MODIFICATION_WINDOW` as the view-facing predicate for trade modification eligibility (#98).
  - `User::PASSWORD_RESET_EXPIRES_IN = 2.hours` as the single source of truth for token lifetime, mailer copy, and UI hint (#99).
  - `MarketIndex::MAJOR_SYMBOLS` with `array_position` order = MX-first explicit sort (#92).

---

## Issues open at close

None from the sprint scope — all 7 closed via PR merges or wont-fix (#113).

**Deferred to S10:**

- #93 Asset detail revamp — adaptive by type, observations-first
- #94 Alerts revamp — MX-aware rule types
- #100 Earnings revamp — BMV-prominent + watchlist filter
- #101 Notifications revamp — grouped + filterable

All four have mockups ready in `.local/`. Deferred because they're either read-mostly (#100, #101) or require backend additions beyond visual revamp (#93 asset-type routing, #94 MX-aware rule types).

---

## Brutal quote of the sprint

> The 0.5× calibration is real, but it's not a free lunch — each PR's Gemini loop ate ~15min of fix + reply time, and the substantive HIGH-severity catches (tab/panel mismatch in #91, `to_i` truncation in #98, `@user` not set in #99) only emerged in review because the reviewer reads what I assumed worked. The review pass is part of the work, not a step after the work.
