# Scope — Sprint S10 (design-completion-and-invite-readiness)

> Issues assigned to this sprint. State-ful work lives in GitHub (Milestone + Project); here just the initial snapshot + brief reason per issue.

---

## Main work

Four mockup-ready design issues. Ship the simpler two first (#100 + #101) so they're done before the first invite goes out mid-sprint; ship the more substantive two (#93 + #94) after.

| # | Title | JTBD / ADR | Discovery card OK? |
|---|---|---|---|
| #100 | Earnings calendar revamp — BMV-prominent + watchlist filter | JTBD: earnings awareness | ✅ |
| #101 | Notifications inbox revamp — grouped + filterable es-MX | JTBD: notification triage | ✅ |
| #93 | Asset detail revamp — adaptive by type, observations-first | JTBD: asset research depth | ⚠️ verify backend implications at open |
| #94 | Alerts revamp — MX-aware rule types + sober UI | JTBD: market awareness automation | ⚠️ verify rule-type additions at open |

**Total estimated raw effort:** ~10-13h (~6-8h actual per S08/S09 calibration ~0.55×)

## Parallel work (max 30% effort)

| # | Title | Parallel axis | Discovery card OK? |
|---|---|---|---|
| #124 | Logo audit — visual consistency + fallbacks | design / polish | ✅ |
| #125 | Bug triage + reactive fixes during first beta invite | ops / reactive (reserve capacity) | ✅ |

**Parallel effort:** #124 ~2-3h fixed + #125 ~3-5h reserved. Total parallel ~5-8h ≈ 30-40% of core. Slightly above the 30% ceiling but #125 is reserve capacity that flexes — if nothing surfaces, the time returns to core.

---

## Rules verified at opening

- [x] Each issue has a complete discovery card — 6/6 (4 design + 2 newly created with full DoD)
- [x] Total `In Progress` issues ≤ 7 (hard rule) — 0 currently; 6 max during sprint
- [⚠️] Parallel ≤ 30% of total estimated effort — at boundary; explicitly justified by reserve-capacity model
- [x] `GOAL.md` goal is covered by the selected issues — yes: 4 core close the design arc, 2 parallel cover polish + reactive validation
- [x] `blocked` issues have their dependency identified — none blocked; #93 + #94 have **backend implications** that surface in their discovery audit

---

## Discovery-card audit applied at sprint open

S07/S08/S09 carry-over discipline. Findings to verify at start of each issue:

- **#100 (Earnings):** check that BMV earnings data source exists / is wired. If not, this becomes a "MarketData query addition + view revamp" combined.
- **#101 (Notifications):** verify the notifications table + creation flow are already operational. The revamp is presentation-layer only; if the underlying creation flow has gaps, those are separate issues.
- **#93 (Asset detail):** the mockup is "adaptive by type" — different render trees for stock vs crypto vs CETES vs ETF. Check whether MarketData already exposes the per-type fields (yield_rate, maturity_date for fixed_income; etc.). Backend additions if not.
- **#94 (Alerts):** "MX-aware rule types" — verify which rule types exist today vs which the mockup proposes. New rule types = backend AlertRule schema additions + EvaluateRule logic extensions.
- **#124 (Logo audit):** inventory pass before any fix. Document findings in commit or `docs/design/logo-audit.md`.
- **#125 (Bug triage):** **invite goes out mid-sprint**, ideally after #100 + #101 ship and before #93 + #94 close.

---

## Sprint sequence (suggested)

1. **Days 1-2:** #100 Earnings + #101 Notifications (simple, ship fast)
2. **Day 3:** #124 Logo audit + invite preparation (e2e manual test, monitoring smoke)
3. **Day 3 evening:** Send first beta invite
4. **Days 4-5:** #93 Asset detail + #94 Alerts (substantive)
5. **Throughout:** #125 reactive bucket for whatever the invite surfaces
6. **Day 6:** S10 close, retro, S11 scope planning

---

## Deferred (out of S10 scope)

- Admin views Lumen migration
- Public marketing site
- Performance benchmarking
- Notification delivery infrastructure changes (UI revamp only)
- i18n adoption (closed wont-fix in S09 #113)

---

## Risks and mitigations

- **First beta invite surfaces blocker-severity bug.** Mitigation: #125 has ~3-5h reserve. If the reserve runs out and more keeps coming, that's the signal to scope-cut on #93 or #94 rather than power-through.
- **#93 + #94 backend implications are larger than estimated.** Mitigation: discovery audit at start of each catches this. If audit shows 2× scope, defer either to S11.
- **Logo audit surfaces inconsistencies that touch many files.** Mitigation: timebox to 3h; if more is found, document in `docs/design/logo-audit.md` and ship the high-impact fixes only, defer cleanup tail.
- **Cross-cutting spec updates as in S09.** Mitigation: budget ~30min per design issue for spec triage (proven pattern).
