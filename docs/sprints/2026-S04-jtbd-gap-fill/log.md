# Log — Sprint S04 (jtbd-gap-fill)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-15 — Sprint opening: cool-off override #2 (the rule may not exist)

S03 retro 2026-05-15 set the default behavior for S4 opening as **respect the 24h cool-off, no override**. That default lasted ~5 hours: Adrian requested opening S04 the same day. This is the **second consecutive override** (S2→S3 was the first).

Pattern observed: 2-of-2 sprint transitions overrode the cool-off. The rule may not exist in practice. **Carry to S04 retro:** if S4→S5 also overrides, drop the cool-off rule from `project_working_method.md` memory and the protocol README. A protocol rule that gets overridden 100% of the time is theater, not protocol.

Decision: open S04 today. Logged explicitly as an override (not a slip).

---

## 2026-05-15 — Code-state audit before commit (#29 CETES, #40 Notable Observations)

Per S03 retro action item ("code-state audit before commit"), audited the surface of both main issues at opening. Findings:

**#29 (CETES maturity per position):**
- ✅ `Position` does NOT have `maturity_date` — migration required (matches DoD).
- ✅ `Asset.maturity_date` exists and is overwritten on every `SyncCetes` run (`app/contexts/market_data/use_cases/sync_cetes.rb:40`). The DoD's "stop overwriting" requirement is correct: the abstract asset's maturity is meaningless because CETES rolls; the lot maturity is what matters.
- ⚠️ `ExecuteTradeContract` and `Trading::UseCases::ExecuteTrade` exist — need to add optional `maturity_date` field for `asset_type == 'cetes'`. Surface unchecked at opening; will verify when work starts.
- ❌ `Alerts::Handlers::EvaluateMaturityAlerts` does not exist. New file.
- ❌ Dashboard "Upcoming events" / CETES near-maturity section does not exist. New partial.
- Seeds and `LoadAssetDetail` use case already read `asset.maturity_date` — both will need to be updated to read from position when applicable (asset-level fallback may need to be removed entirely).

**#40 (Notable Observations):**
- ❌ `TechnicalObservation` model does not exist. New migration + model.
- ❌ `DailyTechnicalObservationsJob` does not exist. New job.
- ✅ `TrendScore` 5-factor exists (survived S03 deletion) and remains the internal observable. Indicators (RSI, MA, BB) need to be readable from existing services or computed in the job — verify at work start.
- ❌ Dashboard "Notable Observations" section does not exist. New Turbo Frame.
- ❌ Asset detail "recent observations" block does not exist. New partial.

**Zero DoD-vs-reality reconciliations expected.** Both discovery cards are honest about the additive nature of the work. If anything surprises mid-sprint, log here.

---

## 2026-05-15 — Estimate calibration: 1.5× because new-feature sprint

S03 retro:
> "Calibration: for sprints that are mostly deletion + refactor on a well-audited surface, the 1.5× Gemini multiplier on raw hours is too pessimistic. Use 1.2× for deletion-heavy sprints, keep 1.5× for new-feature sprints."

S04 is overwhelmingly new-feature. Both #29 and #40 are net-additive (migrations, models, jobs, views). Applying 1.5× per S03 retro calibration → 19h raw × 1.5 = 28.5h. Inside the 25–30h band that S03 originally projected (and S03 came in at 12h actual — but S03 was a deletion-heavy sprint with the calibration nuance now codified).

**Track at retro:** did the 1.5× hold for a new-feature sprint, or is it still pessimistic? Calibration data point #2.

---

## 2026-05-15 — Screenshots baseline strategy

S03 retro carry-over: "Establish `docs/screenshots/` baseline at S4 opening. Light commit: pre-S4 captures of `/dashboard`, `/portfolio`, `/admin` top rows."

Current state: `docs/screenshots/` has files dated 2026-05-08 (pre-S2). They reflect a state where:
- Dashboard shows MXN+USD as if they were the same number (#28 not yet landed).
- KpiCard was 2 partials (`_stat_card` + `_admin_kpi_card`), not unified.
- Admin panels used hardcoded colors instead of semantic tokens.

Decision (Adrian 2026-05-15): **defer regeneration to S04 close**. The S03 retro carry-over wording ("light commit pre-S4") privileged speed over fidelity; in practice the existing screenshots reflect a pre-S2 state that no longer exists, so a "baseline" captured today would already be artificially fresh and not give us a meaningful pre/post delta. Better: at S04 close, capture a single set that represents S2+S3+S4 cumulative visual state. The pre-2026-05-08 screenshots remain in tree as historical reference.

**Carry to S04 close:** regenerate `/dashboard` (post-#28 MXN consolidation + post-#29 CETES upcoming events + post-#40 Notable Observations frame), `/portfolio`, and `/admin` top rows. Commit as part of the QA pass.
