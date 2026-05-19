# Log — Sprint S09 (design-pass)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-19 — Sprint opening: 24h-pause rule overridden

S08 closed 2026-05-19 with PR #114 (close artifacts) merged same day. S09 opens same day — **24h-pause rule overridden consciously.**

Counter status:
- S05→S06: overridden
- S06→S07: overridden
- S07→S08: **respected** (the first time)
- S08→S09: overridden (today, 1st after the first respect)

Per S07 retro: "third consecutive override would invalidate the rule". This is the 1st override after honoring once — not yet a pattern-break, but on watch. **S09→S10 should honor the pause** to preserve the rule. If S09→S10 also overrides, the rule is effectively dead and should be either retired or rewritten.

---

## 2026-05-19 — Initial scope set

Scope agreed with Adrian on 2026-05-19:

**Core (critical path, 4 issues):**
- #90 Dashboard revamp — unlocks visual verification of S08 C1 truthful math
- #91 Portfolio revamp — mixed-MXN/USD trade form coherent with C1
- #98 Trades (Movimientos) revamp — auditable history, same family as #91
- #99 Password recovery — closes auth family (login + register already es-MX)

**Optional (2 issues, opportunistic):**
- #92 Market explorer revamp — MX indices first
- #97 Profile revamp — settings-focused

**Quick win paralelo (1 issue):**
- #113 i18n Go/No-Go decision card — closes the Gemini repetition loop

**Deferred to S10 (mockups ready, lower critical-path):**
- #93 Asset detail, #94 Alerts, #100 Earnings, #101 Notifications

**Closed as superseded:**
- #83 (S08 design pass research) — S08 took compliance + correctness direction; the per-screen design issues now carry the design-pass intent.

---

## 2026-05-19 — PR #115 review pass

Gemini caught a real mistake in this PR: my initial commit had all 5 sprint docs at their template state, not the sketched content. Cause: my Write tool calls right after `cp` from `_template/` failed silently with "File has not been read yet" errors and I committed without verifying. Reviewer flagged the unpopulated placeholders correctly.

Lesson: **never commit a file created via Write without re-reading it**, especially when it was first generated via `cp` or any non-Edit path. The Read-then-Write contract exists exactly to prevent this kind of slip. Captured as failure mode worth remembering for the AP review.

Fixed by re-Reading each file and re-Writing with the intended content. Replied inline to all 7 review comments.

---

## 2026-05-19 — All 7 PRs shipped in a single working day

After the S08→S09 transition, executed all 7 in-scope issues sequentially: #90 → #91 → #98 → #99 → #92 → #97 → #113. Each as its own branch + PR + Gemini review + applied fixes + merge. Workflow per PR followed the established loop (discovery audit → implement → spec → suite green → push → review → fix → re-push → merge).

Notable per-PR moments:

- **#90 Dashboard (PR #116):** introduced `DashboardHelper#format_currency_mx` + `dashboard_greeting`. Co-fixed sessions/registrations flashes ("Welcome back" → "Qué gusto verte de vuelta", etc.) because they'd render next to the now-es-MX dashboard. Gemini review caught a Date.current consistency issue inside `compute_cetes_summary` — collapsed to single-pass `each` with date captured once.
- **#91 Portfolio (PR #117):** added currency selector + FX rate override to the trade form. Pre-Lumen `_kpi_card` (admin-shared) was left alone; created dashboard-specific `_kpi_card`. **HIGH-severity Gemini catch:** tab buttons in `_allocation_sidebar` were reordered to "Por tipo" first per discovery card, but the panels below stayed Sector-first — clicking "Por tipo" showed Sector chart. Tabs controller pairs by index. Reordered panels + added a code comment about the index-pair contract.
- **#98 Trades (PR #118):** new `Trade::MODIFICATION_WINDOW = 30.days` + `Trade#editable?` predicate to replace inlined time-arithmetic in the view. New `TradesHelper#trades_summary_by_currency` for single-pass aggregation. **HIGH-severity Gemini catch:** `trade.shares.to_i` in the success flash was truncating fractional/crypto values (10.5 → 10). Dropped the cast.
- **#99 Password recovery (PR #119):** closes the auth family arc that started with S08 #95 (login) + #96 (register). New `User::PASSWORD_RESET_EXPIRES_IN = 2.hours` constant + `ApplicationHelper#duration_in_words_es` so view + mailer share one source. **HIGH-severity Gemini catch:** validation failure branch in controller wasn't setting `@user`, so the edit view never showed errors. Refactored `ResetPassword` use case to top-level imperative structure (find → contract → update → success) where both contract and update failures attach errors to the User model.
- **#92 Market (PR #120):** new `MarketIndex::MAJOR_SYMBOLS` with `array_position` SQL ordering so IPC always renders first regardless of insert order. Extracted `MarketHelper#vix_tier` + `#trend_strength_label` from views.
- **#97 Profile (PR #121):** removed the watchlist embed (redundant with /dashboard + /market). 4-tab settings layout. Added `preferred_currency` selector wired through `UpdateInfo`. ARCO data-export action via pre-filled `mailto:` to support. **Important Gemini catch:** I had been using **"NLFPDPPP"** as informal shorthand for the post-DOF-2025-03-20 law — the official acronym stays "LFPDPPP" (the name didn't change, only the content). The typo had propagated to **12 files** across S08 + S09. Fixed cross-repo in this PR.
- **#113 i18n decision (PR #122):** No-Go for now. Adrian's framing was important: *"si esperemos hasta despues o cuando no haya features o trabajo que hace donde podamos gastar llm tokens, pero por ahorita para el siguiente sprint serian cosas de mas valor"*. Captured two explicit re-visit triggers (bilingual product goal OR idle capacity) in CLAUDE.md + memory. The decision file is the canonical answer for future Gemini repeats.

---

## 2026-05-19 — Anti-pattern committed (and resisted in S09)

**Sequential execution again.** S08 retro flagged that 4 disjoint PRs were paralelizable; the parallelize feedback memory was created. But S09 also ran all 7 PRs sequentially. Justification this time was different and more defensible: each PR's Gemini review fed substantive fixes into the next PR's awareness (e.g. the `f.text_field` form-builder pattern caught on PR #121 informs how I'd write future forms). Parallel execution would have given me 7 isolated agents each missing the lessons that compounded across the sequence.

Still, the calibration suggests parallelization is mostly underused, not wrong. The S08 retro rule stands; this sprint was a justified exception, not a rebuke.

---

## 2026-05-19 — Cross-repo NLFPDPPP fix in PR #121

This deserves its own note. I introduced "NLFPDPPP" (with the N) in S08 as my informal way to say "Nueva LFPDPPP, post-DOF-2025-03-20". That was a category error — the law's name didn't change. The official acronym stays **LFPDPPP**. By the time Gemini caught it in PR #121 (a single line in `_data_session_tab.html.erb`), the typo had spread to:

- `app/views/legal/privacy.html.erb` (7 instances)
- `app/views/registrations/new.html.erb` (1)
- `app/views/profiles/_data_session_tab.html.erb` (1)
- `app/contexts/identity/contracts/register_contract.rb` (1, comment)
- `docs/sprints/2026-S08-beta-readiness/{scope,qa,GOAL,log}.md` (5)
- `docs/architecture/adr/0008-privacy-notice-domicile-disclosure.md` (2)
- `docs/ops/arco-procedure.md` (6)
- `spec/contexts/identity/use_cases/register_spec.rb` (1)
- `spec/requests/legal_spec.rb` (2)

= 26 occurrences across 12 files. Fixed cross-repo in PR #121 commit `936158b`. Lesson: **legal acronyms get checked against an authoritative source on first use**, not propagated from intuition. Especially when the spec describes the law itself and a regulator could read it.

---

## 2026-05-19 — S09 close: all 7 in-scope issues resolved

- #90, #91, #92, #97, #98, #99, #113 closed via PR merges or wont-fix.
- Issue #98 didn't auto-close on PR #118 merge (commit message used "Closes #98" but something didn't trigger the link). Closed manually with comment for traceability.
- Suite at close: 2353 examples, 0 failures. Coverage held >94%.
- No new ADRs this sprint (only doc updates to ADR-0007/0008 by reference).
- `Stockerly::SUPPORT_EMAIL` constant introduced in S08 #110 paid off — used cleanly in /profile data-export links without copy-pasting.
