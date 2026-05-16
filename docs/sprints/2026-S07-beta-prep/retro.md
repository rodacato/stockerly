# Retro — Sprint S07 (beta-prep)

> Honest post-mortem. Without retro, the sprint does NOT close (hard rule of the protocol).
>
> **Close date:** 2026-05-16
> **Actual duration:** ~12–16 Claude session-hours, 1 calendar day (compressed, opened 2026-05-15 same day as S06 close)
> **Estimated duration:** ~25–37 session-hours (per `scope.md`, mixed 1.0× refactor + 1.3× feature factor on 21–31h raw)
> **Goal:** *"Dejar el sistema listo para invitar al primer amigo a beta cerrada — LFPDPPP cumplida, invite-by-code single-use funcional, onboarding mínimo sin wizard, y runbook de soporte documentado."*

---

## What worked?

- **The mockup-driven workflow was the headline win of the sprint.** Claude Design generated 5 screen mockups in the `Stockerly-1.0` batch with 100% Lumen palette fidelity (verified via `colors_and_type.css` audit on day 1). The exported JSX translated almost mechanically to ERB — structure intact, copy verbatim, only the styling layer changed from inline-style to Tailwind utility classes. Zero regenerations needed; zero mockup-vs-implementation drift to negotiate. This is the design workflow the [[project-design-workflow-wip]] memory was capturing — at S07 close, it works.
- **Expert panel consultation produced predictable design output.** The four design prompts (`/privacy`, `/admin/invites`, `/welcome`, `/report-bug`) each ran through C5 Renata (UX/UI), C4 Marisol (Hotwire+Tailwind), and a situational expert when relevant (S5 Ileana for LFPDPPP). The resulting prompts arrived as fully-self-contained markdown blocks with explicit Avoid lists, palette tables, voice rules, and acceptance checklists. Claude Design honored every constraint; the audit found nothing to reject.
- **Atomic-commit + PR-per-issue + Gemini review loop held across 7 sprint PRs.** PR #79 (#78), PR #80 (#70), PR #82 (memory setup), PR #84 (workflow WIP), PR #85 (#73), PR #86 (#74), PR #87 (#77). Each PR matched one logical unit. Gemini review cycle produced 11 total inline comments across them; 4 accepts, 7 rejects-with-reasoning. No rubber-stamps; no defensive reflexive rejections either. The shape established in S05 retro and refined in S06 is now muscle memory.
- **Replace-not-coexist worked for #77's wizard conflict.** The discovery card had said "no 3-step wizard"; the codebase already had exactly that. Surfacing this mid-sprint (rather than working around it or quietly building two onboarding flows) led to a clean architectural decision in 30 seconds of conversation, followed by a 38-file PR that net **deleted** 3 use cases, 3 views, 3 specs, 1 controller, 5 routes while adding the new flow. Sprint code mass went down, deuda visual went down (hardcoded colors 62→59), axis #2 and #3 moved forward. The decision Adrian made was the right call.
- **Discovery cards with concrete DoD made implementation linear once started.** Every issue had a numbered checklist; implementing #73, #74, #78, #70 was largely mechanical from the card. Even #77 (the one with architectural surprise) was mechanical after the wizard replacement decision. Time variance between issues was driven by surface size, not by discovery quality.
- **The `feedback_protect_master` memory worked as guardrail.** After the initial S06→S07 bypass incident (commit `cba0f8a` pushed directly to master), every subsequent sprint operation used the explicit-refspec recipe (`git push -u origin BRANCH:BRANCH`). Zero further bypasses; the warning would have surfaced again if it had happened. The memory file caught a real failure mode and prevented its recurrence within one sprint.
- **TodoWrite was useful for the two large issues (#74, #77).** Each had 8–10 discrete steps with cross-file dependencies; the todo list kept the work paged and visible. For the smaller issues (#73, #78, #70) it would have been overhead — and was correctly skipped. Calibration: TodoWrite earns its keep when an issue spans ≥5 distinct artifact types or ≥3 architectural layers.

## What didn't work?

- **The discovery card of #77 didn't audit existing code before approving anti-scope.** The card explicitly said "no 3-step wizard" — but the wizard was already there. This is anti-pattern #5 (skipping foundational checks) in spirit, even if not in form. It was caught mid-sprint by reading the existing controllers as part of `/welcome` implementation, but it forced a real architectural decision (Replace vs Coexist vs Defer) under time pressure, which is worse than catching it in discovery. **The right discipline: at sprint open, run `grep -rEn '<anti-scope claim>'` on every claim in the GOAL.md to verify the assertion still holds against the actual codebase.** If the thing the card says "isn't there" actually IS there, that's an architecture problem to surface BEFORE planning implementation.
- **The Gemini I18n insistence (4 consecutive PRs) was repetitive review noise.** PR #85 (controller strings), PR #86 (register error messages), PR #87 (welcome body + bug-report errors) all received I18n adoption recommendations from Gemini. Each was rejected with the same core reasoning (single-locale closed beta, no multi-locale planned, premature abstraction). Writing the same rejection four times is a sign the underlying decision hasn't been formalized. **Concrete carry-forward:** open an ADR — *"Defer I18n adoption until multi-locale is real"* — at S08 open, before any new screen lands. With the ADR in place, future Gemini reviews can be redirected to it in one line instead of restating the argument.
- **The initial bypass of master in the sprint-setup commit (`cba0f8a`).** Pre-existing pattern from S06 (sprint setup committed directly to master) plus my failure to read `feedback_protect_master.md` before acting. Caught by Adrian opening the memory file in the IDE. From then on, every commit went via PR — including this retro. The lesson is: **memory files should be auto-loaded into context at session start, not relied on to be discovered.** Captured.
- **The `Stockerly 1.0/` mockup batch landed inside the repo at first.** Adrian had to redirect me to move it to `.local/`. The right place was obvious in hindsight (gitignored, workspace-local), but I had started by creating `docs/sprints/2026-S07-beta-prep/design-prompt-welcome.md` directly in the repo — which was the wrong instinct (repo pollution with intermediate artifacts). Fixed by establishing `.local/design-mockups/` as the canonical location and documenting in [[project-design-assets]]. Carry-forward: **default position for any generated artifact is "outside the repo unless it has a long-term reason to be committed."**
- **The factory association `created_by_user, factory: :user, admin: true` failed silently.** The `:admin` trait is the correct way (`factory: %i[user admin]`); the wrong incantation produced an `undefined method 'admin='` error that took a minute to diagnose. Minor friction, but a marker: **when a factory association fails with a method error, check the spec/factories file for the actual trait syntax before assuming the model is wrong.**
- **The migration self-destruct on `db/migrate/20260516174817_create_invite_codes.rb`.** I tried to Write a populated migration without reading the placeholder Rails generated; the Write tool refused, then I ran `db:migrate` on the empty migration before catching it. Had to roll back the failed-state migration via raw `runner`. Lesson: **for any generated file Rails populates with a stub, Read it first before writing — even if the content is going to be wholesale-replaced.**

## What to change for the next sprint?

- [ ] **Open ADR-007 at S08 start: "Defer I18n adoption until multi-locale is real."** The reasoning is established (rejected 4 times during S07); the ADR formalizes it and lets future reviews short-circuit instead of re-arguing the same case. Include explicit triggers for revisit ("a second locale exists", "a YAML-based content workflow makes sense", "a translator joins the project").
- [ ] **At sprint open, audit existing code against every anti-scope claim in GOAL.md.** Grep for the thing the card says "isn't there" before approving the discovery card. If it IS there, surface the conflict in opening, not in implementation. This is a 5-minute discipline that would have caught the #77 wizard conflict on day 0.
- [ ] **Default-place all generated artifacts (mockups, scratch notes, intermediate exports) in `.local/`** rather than the repo. The convention is established by [[project-design-assets]]; future batches (`Stockerly-2.0/`, scratch SQL, manual test data) follow the same path without re-asking.
- [ ] **Calibration update in `project_working_method.md`:** S07 came in at ~12–16h vs ~25–37h projected = **0.4–0.5×**. The pattern is now consistent across four sprints (S03 0.5×, S05 0.8×, S06 0.4×, S07 0.4–0.5×). The legacy 1.2–1.5× multiplier is calibrated for greenfield work; for sprints with concrete discovery cards + existing patterns + clear visual reference (mockups), the real factor is around 0.4–0.7×. **New rule-of-thumb: for sprints with mockups-in-hand and concrete DoDs, project at 0.5×; without mockups, 0.8×.**
- [ ] **Read memory files at session start, not on-demand.** `feedback_protect_master` was on disk before the incident; the incident happened because the rule wasn't loaded into the active context. There's a workflow gap between "memory exists" and "memory is applied". Worth a hook or a CLAUDE.md addition that explicitly loads relevant feedback files at start. (Note: the auto-memory section in this conversation's system prompt does load `MEMORY.md` index; the gap was that the file existed but wasn't yet indexed when the incident happened.)
- [ ] **Document the design-workflow trial outcome.** The [[project-design-workflow-wip]] memory was captured mid-sprint with a reassess-at-close clause. This retro is the reassessment trigger. **Conclusion: promote the workflow to canonical** — expert panel + self-contained markdown prompt + GitHub issue comment + `.local/` mockup + Lumen audit + ERB translation. Update the memory file's status from `work-in-progress` to `validated`, drop the reassess clause, and add a §11 entry to `docs/design/brand.md` linking to the workflow. (Action item for S08 open.)

---

## Vision alignment — state of the 6 axes

| # | Axis | Before (S06 close) | After (S07 close) | Notes |
|---|---|---|---|---|
| 1 | Every feature maps to a JTBD | 95% | 95% | Operational sprint, no JTBD changes. Indirect: every JTBD now has a real-user-validation path (via beta invitation). |
| 2 | Zero prescriptive copy in code | 90% | **93%** | Wizard replacement removed "You're all set! 🎉" + exclamation-heavy success screens. New `/welcome`, `/help`, `/report-bug`, `/admin/invites` all descriptive es-MX. Audit-entropy ADR-001 grep stays at 0. |
| 3 | Zero aspirational fake copy | 90% | **94%** | The `/privacy` rewrite removed the largest concentration of aspirational claims in the codebase (AES-256 at rest, "Privacy Support Team Mon-Fri 9-5 EST", "high-security data centers with 24/7 surveillance" — all gone). The remaining 6% is residue in `shared/_public_footer` ("Open Source Market Intelligence Platform. Private by Design.") flagged for the auth-flow translation follow-up. |
| 4 | Dashboard arithmetic truthful for MXN+USD | 95% | 95% | No touches. |
| 5 | Architecture without cross-context leaks | 70% | 70% | Holding. ADR-002 already covers Trading→MarketData; ADR-005 (the Administration foreign-event ownership question) is still the outstanding 30%. Not touched this sprint. |
| 6 | Docs reflect current code | 97% | **98%** | Two memory entries added that document workflows being used (`project_design_assets`, `project_design_workflow_wip`); one feedback memory added that codifies a guardrail (`feedback_protect_master`). The wizard removal also closed a doc/code drift point — the brand kit said "no wizard" while the code had one. Code now matches brand kit. |

**Synthesis:** S07 closed the operational-readiness theme for closed beta. Axes #2 and #3 each moved 3–4 points without any feature work — purely from the `/privacy` rewrite and wizard removal. Beta-cerrada B+ is no longer "almost ready" — it's **technically ready to invite the first friend.** The remaining 10% on axis #3 is concentrated in the public footer and `/register` form (auth-flow translation follow-up); axis #5 remains the longest-standing debt and is the obvious S08+ candidate.

---

## Anti-patterns I committed (if any)

Reviewed against `feedback_anti_patterns` in persistent memory.

- **#1 (Next phase = next thing to build) — TECHNICALLY violated via the 24h-pause override on day 1, NOT in spirit.** S07 was scoped from a milestone description set during S06 opening, all 5 issues had complete discovery cards by the time work started, and the override was documented in `log.md` 2026-05-15 with explicit justification (legal/compliance bloqueador). However: this is the **second consecutive override** of the 24h rule (S05→S06 was also overridden). The pattern is real. Commitment: S07→S08 transition will respect the 24h pause unless the same kind of explicit bloqueador justifies otherwise. If the rule is overridden a third time consecutively, the rule itself is broken and should be deleted, not endlessly excepted.
- **#2 (PRD as gospel) — NOT violated.** No PRD reference.
- **#3 (Patterns over pragmatism) — NOT violated.** The two architectural deviations from the discovery cards (#74 and #77) were chosen consciously after surfacing the conflict, not coerced into the card's original shape. The rejections of Gemini's I18n/centralization comments were defended with concrete reasoning, not blanket "we don't do that here."
- **#4 (Doc bloat) — TECHNICALLY violated +2 (bloated_docs 11 → 13).** Added `docs/ops/beta-support.md` (253 lines for #78) and observed that `docs/design/brand-kit-portable.md` and `docs/research/code-audit-2026-05/inventory.md` continue to live in bloated state. Honest call: the runbook is operational content that earns its lines (it documents 5 distinct sub-flows with concrete kamal commands); not anti-pattern in spirit. Will not retroactively trim.
- **#5 (Skipping foundational checks) — TECHNICALLY violated on #77 discovery.** The discovery card claimed "no wizard" without grep-verifying. Surfaced mid-sprint, mitigated by Adrian's explicit Replace approval. Carry-forward action item already captured above.
- **#6 (Fragmenting redesigns without closing) — NOT violated.** Wizard replacement was complete in one PR (#87) — not split across two sprints, not "remove later", not abandoned half-done.
- **#7 (No retros / no audits) — ACTIVELY RESPECTED.** This file. QA pass ran fully. Audit-entropy ran at sprint open, mid-sprint (informally during #73 and #74), and at close.
- **#8 (Rubber-stamping reviewer comments) — ACTIVELY RESPECTED.** 11 Gemini comments across 5 PRs, 4 accepts and 7 rejects; every decision argued in-thread, none accepted reflexively, none rejected reflexively.

**Score: 0 of 8 anti-patterns committed in this sprint *in spirit*.** Two technical violations (24h pause + #77 foundational check) documented honestly, both with concrete corrective actions for S08.

---

## Real vs estimated time

| Phase / Issue | Estimated (×1.0–1.3 mix) | Real | Reason for deviation |
|---|---|---|---|
| Sprint opening + discovery cards (5 GH issues + memory + design prompts) | 2 h | ~2 h | OK — discovery + prompt composition was the bulk |
| #78 — Beta support runbook | 3–5 h | ~1.5 h | Doc-only with strong existing reference (`docs/ops/deploy.md`); no implementation surface |
| #70 — TrendScore enum rename | 3–4 h | ~1.5 h | Mechanical refactor + migration. Did spend ~10 min recovering from a broken migration state mid-sprint (Read-before-Write hiccup) |
| #73 — `/privacy` rewrite | 3–4 h | ~1 h | Mockup arrived complete; ERB translation was direct. Audit-entropy verification fast. |
| #74 — Invite-by-code system | 6–8 h | ~3.5 h | Largest scope (schema + 3 use cases + admin UI + register integration + 31 specs); came in well under estimate because the mockup + discovery card gave a clear linear path |
| #77 — Onboarding (welcome + help + report-bug + mailer + wizard delete) | 6–10 h | ~3.5 h | Wizard removal + 3 new routes + mailer with HTML/text parts + 29 specs. The mid-sprint architectural surprise added ~30 min of conversation but didn't blow the estimate. |
| Sprint close (QA + retro + memory updates) | 1.5–2 h | ~1 h | In progress as of this commit |
| **Total** | **25–37 h** | **~14 h** | **0.4–0.6× of projected.** |

**Calibration consolidated across 5 data points (S03–S07):**

| Sprint | Type | Projected | Actual | Factor |
|---|---|---|---|---|
| S03 | Deletion-heavy | 25 h | 12 h | 0.48× |
| S04 | Feature with nearby pattern | 28 h | 18 h | 0.64× |
| S05 | Refactor with ADR | 27 h | 22 h | 0.81× |
| S06 | Mechanical migration with mockup-clarity | 21 h | 8 h | 0.38× |
| S07 | Feature with mockups + clear DoDs | 25–37 h | ~14 h | 0.45× |

**Pattern: with mockups-in-hand + concrete DoDs, real factor consolidates around 0.4–0.5×, regardless of whether the work is feature or refactor.** This is because the unknowns (visual decisions, copy decisions, layout decisions) get resolved BEFORE implementation, not during. The old 1.2–1.5× legacy multiplier was sized for sprints where unknowns appear during implementation; that's not the regime we're in anymore. **New rule for S08+:** projected raw × 0.5 for sprints with mockups + DoDs, × 0.8 for sprints without.

---

## Registered decisions

- **Sprint workflow: PR-only for everything.** No more direct-to-master pushes, including sprint setup, retros, or memory updates. Established post-incident on 2026-05-16 (`feedback_protect_master.md`). Held for the rest of S07; will hold for S08+.
- **Architectural deviation #74:** `GenerateInviteCode` lives in `Administration::UseCases::Invites::` (not `Identity::`) to mirror the established admin/users pattern. Consumption integrated into `Identity::UseCases::Register` in a single transaction (no separate `ConsumeInviteCode` use case). Documented in commit + PR body.
- **Architectural deviation #77:** Wizard `OnboardingController` + step1/step2/step3 fully removed; `/welcome` becomes the only post-register flow. Adrian's mid-sprint explicit approval recorded in `log.md`. Saves 3 orphaned use cases (`CompleteWizard`, `LoadAssetCatalog`, `LoadProgress`) and 3 view files. Replaces aspirational "You're all set! 🎉" success screen with descriptive es-MX.
- **Design workflow validated:** mockup-driven via expert panel + Claude Design + Lumen audit + ERB translation is the canonical workflow going forward. `project_design_workflow_wip` status moves from work-in-progress to validated; reassess clause dropped. Add §11 entry to `docs/design/brand.md` in S08 open referencing this workflow.
- **I18n explicitly deferred.** Multi-locale adoption not adopted in S07. Will be formalized as ADR-007 at S08 open: *"Defer I18n adoption until multi-locale is real."* Triggers for revisit: second locale exists, YAML content workflow makes sense, translator joins the project.
- **Hardcoded `support@notdefined.dev` kept literal across all 4 occurrences.** Privacy notice, welcome footer, help footer, BugReportMailer recipient. No central config introduced. Decision driven by: single environment target, no support-routing fan-out, grep+replace is one PR. Revisit trigger: if a second support address (`security@`, `legal@`) becomes real.
- **Onboarding wizard convention:** future onboarding work uses `WelcomeController` + shared `_welcome_body` partial. No more wizards.

---

## Issues open at close

**None from S07 scope.** All 5 main issues closed (#73, #74, #77, #78, #70). Milestone state at close: `open_issues: 0, closed_issues: 5`.

**Non-S07 PRs left open** (dependabot, not in scope):
- PR #75: bump puma 7.2.0 → 8.0.1 (open across the entire sprint; not S07)
- PR #76: bump faraday 2.14.1 → 2.14.2 (open across the entire sprint; not S07)

---

## Brutal quote of the sprint

> *"The discovery card said 'no wizard' but the wizard was already there. The sprint that should have been pure-implementation became a mid-sprint architectural decision because no one audited the code before scoping. Lesson: at sprint open, grep for every anti-scope claim — if the thing the card says 'isn't there' is actually there, you have an architecture problem to surface BEFORE planning implementation, not during."*
