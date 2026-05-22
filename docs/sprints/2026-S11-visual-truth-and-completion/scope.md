# Scope — Sprint S11 (visual-truth-and-completion)

> Issues assigned to this sprint. State-ful work lives in GitHub (Milestone + Project); here just the initial snapshot + brief reason per issue.

---

## Main work

8 issues. **#142 ships FIRST** — it's the foundation other design completions compound on. The other 7 split into 2 parallel tracks once #142 lands.

| # | Title | JTBD / ADR | Discovery card OK? |
|---|---|---|---|
| #142 | Lumen palette migration in `application.css` | Design-system truth (ADR-0007-adjacent — sprint #1 priority) | ✅ |
| #143 | Dashboard sidebar + main grid revamp (7 partials) | Asset awareness · panel general | ✅ |
| #144 | Asset detail — "Acerca de la empresa" / Ficha block | Asset research depth (#93 follow-up) | ✅ |
| #145 | Trades — filter strip + footer totals + empty-state CTA | Trade transparency (#98 follow-up) | ✅ |
| #146 | Profile — 2-col with IdentityCard sidebar + theme/sessions/3-channel prefs | Identity + control (#97 follow-up) | ✅ |
| #147 | Password recovery — re-implement to centered card + 5 states | Auth flow consistency (#99 follow-up) | ✅ |
| #148 | StatementsHelper line-item labels → es-MX | Language coherence (#132 follow-up) | ✅ |
| #149 | Bug-report mailer — es-MX migration | Operational es-MX completion (#124 follow-up) | ✅ |

**Total estimated raw effort:** ~25-35h (~14-20h actual per S09/S10 calibration ~0.55-0.7×)

## Parallel work (max 30% effort)

| # | Title | Parallel axis | Discovery card OK? |
|---|---|---|---|
| #150 | S11 reactive bucket — beta feedback triage + fixes | ops / reactive (reserve capacity) | ✅ |

**Parallel effort:** #150 reserved 3-5h, flexes with beta amigo response volume. If beta amigo never replies in-sprint, capacity returns to main.

---

## Rules verified at opening

- [x] Each issue has a complete discovery card — 9/9 (just filed 2026-05-22)
- [x] Total `In Progress` issues ≤ 7 (hard rule) — 0 currently; 4-6 max during sprint (depending on parallel-agent batches)
- [⚠️] Parallel ≤ 30% of total estimated effort — #150 reserve is ~15% of estimated; well inside the cap. The Large-scope choice (8 main + 1 parallel) was Adrian's explicit decision at sprint open, acknowledging the S10-retro flag about over-delivery.
- [x] `GOAL.md` goal is covered by the selected issues — yes: #142 closes the visual-truth gap; #143 + #144 + #145 + #146 + #147 close the 3+2 design-completion deferrals; #148 + #149 close the language-coherence tails
- [x] `blocked` issues have their dependency identified — #143, #144, #145, #146, #147 are visually-dependent on #142 (Lumen palette correct) but not code-dependent. They can be authored in parallel and rebased after #142 lands.

---

## Discovery-card audit applied at sprint open

Carry-over discipline from S07/S08/S09/S10. Findings to verify at start of each issue:

- **#142 (Lumen CSS):** Tokens must match `docs/design/tokens.md` exactly. Grep for hardcoded hex (`#005A98`, `#004a99`, `#3BC175`) — any remaining → in-scope fix.
- **#143 (Dashboard):** 7 partials per `AUDIT-operational.md`. Re-verify the partial list against current `app/views/dashboard/` since #116 may have shifted names.
- **#144 (Asset detail Ficha):** Check `MarketData::Gateways::AlphaVantageGateway#fetch_overview` returns data for representative tickers (AAPL works; WALMEX.MX likely no overview from Alpha Vantage).
- **#145 (Trades):** Audit the existing trade-list query — adding totals shouldn't break SQL (use Ruby aggregation on the loaded array, not extra COUNT queries).
- **#146 (Profile):** Backend gaps possible — Session model + multi-session tracking may not exist; per-channel notification prefs may not exist. If so, ship UI with stub backend + flag clearly in PR body.
- **#147 (Password recovery):** Inventory current `PasswordResetsController` flow vs the 5 mockup states. The 3 missing states (forgot-sent, reset-expired, reset-success) may need dedicated routes.
- **#148 (Statements):** Check whether MX-IFRS terminology preference exists in any doc; if not, use plain Spanish equivalents from BMV emisora reports as the convention.
- **#149 (Bug-report mailer):** First read the controller + mailer to see whether there's a user-facing confirmation. If purely server-to-server, document and close as "no change needed" instead of forcing a migration.
- **#150 (Reactive bucket):** Open-scope. Triage when reports arrive per `docs/ops/beta-support.md`.

---

## Sprint sequence (suggested)

**Wave 1 — Foundation (Day 1):**
1. #142 Lumen CSS migration — ship FIRST, sequential, do it myself in main thread

**Wave 2 — Design completions in parallel (Days 2-3):**
2. Launch 2 parallel agents in worktrees:
   - Agent A: #143 (dashboard) + #144 (asset detail Ficha) + #148 (statements es-MX)
   - Agent B: #145 (trades) + #146 (profile) + #147 (password recovery)
3. Both ship 3 PRs each, 6 PRs total this wave

**Wave 3 — Cleanup (Day 3-4):**
4. #149 bug-report mailer — single PR, ~30 min

**Wave 4 — Close (Day 4-5):**
5. Read-only audit pass (2 agents in parallel per the S10-retro adopted ritual) confirms no new structural drift
6. QA + retro + close

**Throughout:** #150 reactive bucket absorbs beta amigo feedback if/when it arrives.

---

## Deferred (out of S11 scope)

- PromoteUser / ResendVerification use cases (#135 stubs)
- Asset `issue_date` column (#132 follow-up)
- Wordmark text-to-paths (#140 follow-up — Adrian's external Figma/Inkscape task)
- Glyph variants doc §11.1 (#140 follow-up — pure docs)
- MetricDefinitions translation (separate decision)
- MissionControl::Jobs UI (3rd-party)
- admin/onboarding wizard (runs once per install)

---

## Risks and mitigations

- **#142 Lumen CSS migration reveals more than 30 LoC of drift.** Mitigation: discovery audit at issue start. If scope balloons to 100+ LoC + multiple view sweeps, split into "Lumen CSS migration" (palette swap only) and "Lumen view sweep" (per-surface fix) — 2 PRs. Don't try to do both in one.
- **Beta amigo response arrives mid-sprint with blocker-severity bug.** Mitigation: #150 reserve absorbs. If reserve exhausts and more keeps coming, scope-cut on the smaller items (#148 statements labels, #149 bug-report mailer) which are polish-tier.
- **Parallel agents collide on shared files** (e.g., `app/views/dashboard/_sidebar.html.erb` if Profile happens to reuse a sidebar component). Mitigation: file-overlap audit before launching agents; coordinate prompts so neither touches the other's areas; rebase order on merge.
- **Large scope (8 main + reactive) reproduces S10's over-delivery anti-pattern.** Mitigation: Adrian explicitly chose Large at sprint open knowing this. Tracking: if we close 6/8 main + #150 the sprint counts as a win; if we close 8/8, flag at retro whether we're calibrating cadence well or hiding a gap.
