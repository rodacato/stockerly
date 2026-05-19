# Scope — Sprint S09 (design-pass)

> Issues assigned to this sprint. State-ful work lives in GitHub (Milestone + Project); here just the initial snapshot + brief reason per issue.

---

## Main work

Six issues. Four core (critical path for first-invite UX coherence) + two opportunistic (mockup-ready, low risk).

| # | Title | JTBD / ADR | Discovery card OK? |
|---|---|---|---|
| #90 | Dashboard revamp — Lumen + MX-first KPIs + es-MX | JTBD #1 (consolidated patrimony truthful; depends on S08 C1) | ⚠️ verify at open |
| #91 | Portfolio revamp — Lumen + mixed MXN+USD trade form | JTBD: portfolio control (multi-currency entry) | ⚠️ verify at open |
| #98 | Trades (Movimientos) revamp — auditable history es-MX | JTBD: portfolio control (audit trail) | ⚠️ verify at open |
| #99 | Password recovery flow — es-MX + Lumen (forgot + reset) | Auth-family completion (closes #95 + #96 set) | ⚠️ verify at open |
| #92 | Market explorer revamp — MX indices first + CETES rates | JTBD: market discovery (MX-anchored) | ⚠️ verify at open |
| #97 | Profile revamp — settings-focused (no watchlist) + es-MX | JTBD: account control | ⚠️ verify at open |

**Total estimated raw effort:** ~16-21h (~8-11h actual per S07/S08 calibration ~0.5×)

## Parallel work (max 30% effort)

| # | Title | Parallel axis | Discovery card OK? |
|---|---|---|---|
| #113 | Decide on i18n infrastructure (Go/No-Go decision card) | meta / architecture | ✅ (the card itself is the discovery — the issue is the decision) |

**Parallel effort:** ~1h (~6% of sprint) — well under the 30% ceiling.

---

## Rules verified at opening

- [ ] Each issue has a complete discovery card (no `discovery-needed` label) — verify at open; #113 has `discovery-needed` but it IS the discovery card (a decision needs to be made during the sprint)
- [ ] Total `In Progress` issues ≤ 7 (hard rule) — 0 currently in progress; 7 max during sprint (6 main + 1 parallel)
- [ ] Parallel ≤ 30% of total estimated effort — ~6% parallel
- [ ] `GOAL.md` goal is covered by the selected issues — yes: 4 critical-path screens cover first-invite UX, 2 optional extend the MX-first surface
- [ ] `blocked` issues have their dependency identified — none blocked

---

## Discovery-card audit applied at sprint open

Each issue should be verified against current codebase state before execution starts. **TODO at open** — apply the S07/S08 carry-over discipline. Findings (to fill in during execution):

- **#90 (Dashboard):** verify the Lumen mockup matches the JTBD #1 invariant; check that the C1 fix from S08 is visible in `TakeSnapshotsJob` output (snapshot.currency populated, total_value MXN-converted).
- **#91 (Portfolio):** verify the trade form mockup includes the FX rate field when buying USD-denominated assets with MXN buying power.
- **#92 (Market explorer):** check that CETES rates source already exists (S07 work) — if so, the revamp is purely visual.
- **#97 (Profile):** confirm the existing profile view doesn't already include the no-watchlist treatment (don't double-work).
- **#98 (Trades):** verify the existing trades index isn't already es-MX.
- **#99 (Password recovery):** confirm `/forgot-password` and `/reset-password` are the two views in scope; check the mockup covers both.

---

## Deferred (mockups ready, S10 candidates)

- #93 Asset detail — adaptive by type, observations-first
- #94 Alerts — MX-aware rule types + sober UI
- #100 Earnings — BMV-prominent + watchlist filter
- #101 Notifications — grouped + filterable es-MX

S09 ships the trader-workflow + auth-completion screens; S10 ships the read-mostly + advanced-feature screens.

---

## Risks and mitigations

- **Mockup-to-Tailwind translation drift.** The mockups use design-system tokens (`var(--sk-fg)`, etc.) that don't always map 1:1 to Tailwind utility classes in this project. Mitigation: keep existing Tailwind classes where they already match the mockup; replace only when divergence is visible.
- **Cross-cutting spec updates.** Like S08 #95 login (which touched ~16 system specs for login labels), the dashboard/portfolio/trades revamps may require spec updates if they rely on English copy. Mitigation: budget ~30min per screen for spec triage.
- **Tests for visual changes.** Visual revamps don't have clean test boundaries; existing request/system specs should keep passing without new assertions on copy unless behavior changes.
- **Designer feedback loop.** Mockups are static. Discrepancies between mockup and rendered HTML may need a second pass. Mitigation: implementer reviews against the mockup screenshot at PR open, not after merge.

---

## Closed as superseded

- **#83** — original S08 design pass research card. S08 took a compliance + correctness direction (B-01/B-02/B-04 + C1) instead of the design pass it originally framed. The design-pass intent now lives in the per-screen issues of this S09 scope.
