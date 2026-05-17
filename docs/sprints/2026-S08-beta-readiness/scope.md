# Scope — Sprint S08 (beta-readiness)

> Issues assigned to this sprint. State-ful work lives in GitHub (Milestone + Project); here just the initial snapshot + brief reason per issue.

---

## Main work

Six issues. Mix of compliance blockers (B-* family from research), correctness P0 (C1), and auth-design (auth-family completion).

| # | Title | JTBD / ADR | Discovery card OK? |
|---|---|---|---|
| #102 | Terms of Service rewrite — es-MX + factual + jurisdiction CDMX (B-01) | Pre-beta-blocker (legal validity of invite acceptance) | ✅ |
| #103 | Risk Disclosure rewrite — eliminate false leverage/margin claims (B-02) | Pre-beta-blocker (civil liability from false declarations) | ✅ |
| #104 | Privacy update (INAI→SABG, retention, remisiones) + ARCO procedure (B-04+B-05) | Pre-beta-blocker (NLFPDPPP DOF 20-mar-2025 compliance) | ✅ |
| #105 | Multi-currency cost-basis P0 — TakeSnapshotsJob uses Portfolio#total_value(currency:) (C1) | JTBD #1 (Consolidated patrimony in MXN truthful for mixed portfolios) | ✅ |
| #95 | Login revamp — es-MX + Lumen | Auth-family coherence + es-MX migration | ✅ (mockup ready en `.local/`) |
| #96 | Register revamp — complete es-MX + Lumen + **B-03 Art. 8 consent** | Auth-family + LFPDPPP Art. 8 express consent for datos patrimoniales | ✅ (mockup ready, B-03 inline scope) |

**Total estimated raw effort:** ~28-38h (~14-19h actual per S07 calibration 0.5×)

## Parallel work (max 30% effort)

| # | Title | Parallel axis | Discovery card OK? |
|---|---|---|---|
| (none) | — | — | — |

S08 has zero `parallel`-labeled work — sprint is single-themed (beta-readiness) with all 6 items contributing to the same goal.

---

## Rules verified at opening

- [x] Each issue has a complete discovery card (no `discovery-needed` label) — 6/6 verified
- [x] Total `In Progress` issues ≤ 7 (hard rule) — 0 currently in progress; 6 max during sprint
- [x] Parallel ≤ 30% of total estimated effort — 0% parallel
- [x] `GOAL.md` goal is covered by the selected issues — 5 blockers + 1 P0 + 2 auth (with B-03 inline) = full coverage of stated goal
- [x] `blocked` issues have their dependency identified — none blocked

---

## Discovery-card audit applied (S07 retro carry-over)

Each issue was verified against current codebase state at sprint open. Findings:

- **#102 (Terms):** `app/views/legal/terms.html.erb` confirmed to contain the exact fakes per research (NY address line 86, fake legal email line 82, stale "October 24, 2023" line 94, fake "Stockerly Legal Dept. v2.4.1" line 95). Discovery card is accurate.
- **#103 (Risk Disclosure):** `app/views/legal/risk_disclosure.html.erb` confirmed to have leverage/margin section (line 49+) and false "Stockerly may close positions" statement (line 60). Discovery card accurate.
- **#104 (Privacy + ARCO):** Current `/privacy` (from S07 #73) does NOT mention INAI or SABG or retention — so B-04 is **additive update** rather than full rewrite. Discovery card refined to reflect this — less drastic than synthesis implied.
- **#105 (Cost-basis P0):** **Research synthesis claimed bug was in `Trading::UseCases::ExecuteTrade` (hardcoded "USD"). Audit revealed otherwise** — `ExecuteTrade` already captures currency + fx_rate correctly. The real bug is in `app/jobs/take_snapshots_job.rb#take_snapshot` which sums `position.market_value` cross-currency without conversion. Discovery card updated to point at correct location. Fix is more tractable than originally thought because the currency-aware infrastructure (`Portfolio#total_value(currency:)`) already exists.
- **#95 (Login revamp):** `app/controllers/sessions_controller.rb` exists. Discovery card accurate. Mockup in `.local/design-mockups/Stockerly-2.0/login/` (validated post-audit).
- **#96 (Register revamp + B-03):** `app/controllers/registrations_controller.rb` exists. Discovery card updated mid-S08-open to include B-03 Art. 8 consent as inline sub-task (migration + form + persistence + spec).

**Lesson reinforced:** the discovery-card audit caught one substantive misdirection (#105 location). Worth keeping as standard sprint-open discipline.

---

## Deferred (mockups ready, S09 candidates)

These Stockerly-2.0 mockups live in `.local/design-mockups/` and are S09 candidates:

- `/dashboard` (#90) — implementación waits for C1 fix so dashboard renders truthful MXN
- `/portfolio` (#91)
- `/market` (#92)
- `/market/:symbol` (#93)
- `/alerts` (#94)
- `/profile` (#97)
- `/trades` (#98)
- `/forgot-password` + `/reset-password` (#99)
- `/earnings` (#100) — mockup pending Adrian's 2026-05-18 Claude Design quota reset
- `/notifications` (#101) — idem

S08 ships the foundations; S09 ships the visual layer on top of truthful + legally-valid foundations.
