# Scope — Sprint S04 (jtbd-gap-fill)

> Issues assigned to this sprint. State-ful work lives in GitHub (Milestone + Project); here just the initial snapshot + brief reason per issue.

---

## Main work

| # | Title | JTBD / ADR | Discovery card OK? |
|---|---|---|---|
| **#29** | [P0] CETES: maturity_date per position + expiry alerts | JTBD #3 (CETE expires in N days) | ✅ (DoD pre-flight audit completed — see log 2026-05-15) |
| **#40** | [feat] Surface 'Notable Observations' for JTBD #6 (technical zone) | JTBD #6 (position in notable technical zone) | ✅ |

## Parallel work (max 30% effort)

| # | Title | Parallel axis | Discovery card OK? |
|---|---|---|---|
| **#37** | [refactor] Adopt semantic color tokens from @theme — S04 slice | Design system (brand migration parallel S3-S6) | ✅ |
| **#59** | [research] Draft ADR-002: Trading ↔ MarketData boundary | Architecture (unblocks #33 for S05) | ✅ |

S04 slice of #37: migrate **2 components + 1 important view** (per S03 close audit-entropy: 194 non-slate hits remaining; target ≤170 at S04 close). Candidate components: `_trend_score_breakdown` + `_position_row`; candidate view: `app/views/market/index` or `app/views/portfolio/show` top sections.

---

## Execution order (decided at opening — see log.md 2026-05-15)

1. **ADR-002 draft first** (~2h raw). Short, frontloaded so #33 has the unblocker ready in case S05 starts earlier than expected. Also doubles as a "warm-up" before the heavier feature work.
2. **#29 (CETES)** — P0, the actual beta-blocker. Migration → contract → use case → handler → dashboard surface → tests. The `EvaluateMaturityAlerts` handler is the only new file in `Alerts::Handlers/`; the rest is additive on existing structures.
3. **#40 (Notable Observations)** — Independent of #29; can run after #29 closes or be picked up as a context switch. Heaviest new-surface delta of the sprint (new model + EOD job + dashboard frame + asset detail block).
4. **#37 S04 slice** — Runs alongside #29/#40 as context-switch breathers. 2 components + 1 view, target ≤170 hardcoded hits.

---

## Estimated effort

> Per S03 retro calibration: 1.2× factor for deletion-heavy sprints, **1.5× for new-feature sprints**. S04 is overwhelmingly new-feature (both #29 and #40 are net-additive features) → applying 1.5×.

| # | Estimate (raw session-hours) | × 1.5 Gemini factor | Notes |
|---|---|---|---|
| #29 (CETES) | 8 h | 12 h | Migration + contract + use case + handler + dashboard surface + Notification dispatch + cooldown + 7d/3d/1d schedule + tests |
| #40 (Notable Obs) | 7 h | 10.5 h | `TechnicalObservation` model + `DailyTechnicalObservationsJob` + dedup + dashboard Turbo Frame + asset detail block + RSI/MA/BB transition detection + tests |
| #37 (S04 slice) | 2 h | 3 h | 2 components + 1 view + audit-entropy regression check |
| ADR-002 draft (#59) | 2 h | 3 h | Research + decision write + 2-3 alternatives + consequences |
| **Total** | **19 h raw** | **~28.5 h** | Inside the 25–30 h calibration band; new-feature mix is honest |

Parallel effort (#37 + ADR draft) = 6h / 28.5h ≈ **21% ≤ 30%** ✅

---

## Rules verified at opening

- [x] Each issue has a complete discovery card (no `discovery-needed` label) — #29, #40, #37, #59 all verified `ready`
- [x] Total `In Progress` issues ≤ 7 (hard rule) — will open ≤ 2 at a time
- [x] Parallel ≤ 30% of total estimated effort — 21%, well within
- [x] `GOAL.md` goal is covered by the selected issues — #29 covers JTBD #3, #40 covers JTBD #6, ADR-002 draft covers the unblocker condition
- [x] `blocked` issues have their dependency identified — none in S04 main; #33 stays blocked (and that's the point — ADR-002 draft removes the block for S05)
- [x] Code-state audit completed at opening (S2 retro change-list) — see log.md 2026-05-15 for #29 and #40 findings
- [x] Screenshots baseline strategy decided at opening (S03 retro carry-over) — defer regeneration to S04 close; see log.md 2026-05-15
