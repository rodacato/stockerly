# ADR-009 — Historical FX rates for cross-currency snapshot revaluation

- **Status:** Accepted · **implemented 2026-08-24** (slice 2b: `FxRateHistory`, `Portfolio#convert(at_date:)`, and `FxRateResolver` preferring the FIX for the trade's own date) · **amended 2026-08-26** ([#318](https://github.com/rodacato/stockerly/issues/318)): the series is `SF60653`, and history is seeded from 1991 rather than collected forward
- **Date:** 2026-06-27
- **Author:** Adrian Castillo
- **Supersedes:** —
- **Related:** [issue #183](https://github.com/rodacato/stockerly/issues/183), [issue #177](https://github.com/rodacato/stockerly/issues/177), [`app/jobs/take_snapshots_job.rb`](../../../app/jobs/take_snapshots_job.rb), [`spec/contexts/trading/domain/multi_currency_audit_spec.rb`](../../../spec/contexts/trading/domain/multi_currency_audit_spec.rb)

---

## Context

The S12 #168 multi-currency calculator audit (and a Gemini code-assist review of PR #181) surfaced an inconsistency in how the portfolio calculators revalue historical data when a snapshot's currency differs from the user's current `preferred_currency`.

| Calculator | Cost-basis handling | FX timing |
|---|---|---|
| `Portfolio#total_unrealized_gain` | Each trade's `fx_rate_at_execution` | Historical ✓ |
| `Portfolio#day_gain` | Revalues yesterday's snapshot via `Portfolio#convert` | **Today's FX** ⚠️ |
| `PeriodReturnsCalculator` | Revalues each snapshot via `Portfolio#convert` | **Today's FX** ⚠️ |

`Portfolio#convert` only knows today's FX rate. When a user changes `preferred_currency` (the `/profile` toggle added in #146), their older snapshots stay in the previous currency, and `day_gain` / `PeriodReturnsCalculator` revalue them at *today's* rate — silently dropping the FX-on-principal effect.

**Concrete impact.** User held USD 3,000 yesterday. FX yesterday 17.00, today 17.50.
- Honest: yesterday in MXN at yesterday's rate = 51,000 → `day_gain = today_mxn − 51,000 = +3,250 MXN`.
- Current code: USD 3,000 × today's 17.50 = 52,500 → `day_gain = today_mxn − 52,500 = +1,750 MXN`.
- Gap: 1,500 MXN of FX appreciation on the principal reported as "no change".

**Why it doesn't manifest today.** `TakeSnapshotsJob` always stores snapshots in the user's `preferred_currency` at snapshot time. As long as that preference is unchanged, snapshots and the current view share a currency, no conversion happens, and there is no gap.

**When it will manifest.** The moment a user toggles `preferred_currency` in `/profile`, the "before" snapshots are in the old currency and any subsequent `day_gain` / period-returns read shows the gap.

This collides directly with the product's first-class invariant — *multi-currency MXN/USD is honest, not a bolt-on* — so an FX-neutral approximation is not acceptable here.

Four options were considered (from issue #183):

| Option | Approach | Cost |
|---|---|---|
| A | Daily `FxRateHistory` table; `Portfolio#convert(amount, from:, to:, at_date:)` | Medium — new schema + daily refresh + callsites pass a date |
| B | Recompute all snapshots into the new preferred_currency when the user toggles | Small — but needs daily FX history anyway, or loses precision on old data |
| C | Lock the preferred_currency toggle for users who already have snapshots | Smallest — defers the problem, breaks the #146 UI |
| D | Accept the imperfection; document that post-switch returns may be FX-neutral | Zero — but contradicts the multi-currency invariant |

## Decision

We take **option A**: a daily `FxRateHistory` store keyed by `(base, quote, date)`, and a date-aware `Portfolio#convert(amount, from:, to:, at_date:)`. `day_gain` and `PeriodReturnsCalculator` use the historical rate whenever a snapshot's currency differs from the target currency; same-currency reads stay on the existing zero-conversion fast path.

This is the only option that keeps the consolidated MXN view honest across a currency switch, and it composes with **#177 (Banxico FX as primary USD/MXN source)**: Banxico's `TC_TC002` series publishes the official daily fix for free, which is exactly the history `FxRateHistory` needs. The two are therefore implemented as **one coherent block** over the FX layer rather than two PRs that would otherwise contend on the same gateway and resolver code.

B is rejected because it still needs the same FX history to be precise, while adding a destructive in-place rewrite of snapshots. C is rejected because it breaks an already-shipped UI to avoid the problem rather than solve it. D is rejected because it knowingly reports FX-neutral numbers in a product whose north star is honest multi-currency consolidation.

## Consequences

**Positive**
- `day_gain` and period returns stay honest after a `preferred_currency` change — the FX-on-principal effect is preserved.
- The history table is fed by the same Banxico integration #177 introduces; no separate data source or cost.
- Same-currency portfolios (the common case today) are unaffected — the date-aware path only triggers on a currency mismatch.

**Negative / risk**
- New schema (`FxRateHistory`) plus a daily refresh job — more surface to keep healthy (the existing `CheckSyncHealthJob` stale-sync alerting should cover it).
- Every historical-revaluation callsite must pass `at_date:`; missing one silently reintroduces the today's-FX gap. Mitigated by the cross-currency cases in `multi_currency_audit_spec.rb` asserting honest values.
- ~~Backfill: history only exists from the day the table starts collecting.~~ **Resolved by the 2026-08-26 amendment** — the whole series is seeded, so no snapshot predates the store.

**Operational requirement**
- The daily FX-history refresh runs after Banxico publishes (~11 AM CDMX, per #177). A missed run leaves a gap day; the calculators fall back to the nearest available rate and the sync-health check flags the staleness.

## Amendment, 2026-08-26 — the settlement series, and a seeded history

The FIX was read from `SF43718`, the series keyed to the day a rate is
**determined**. A broker settles two banking days later, against `SF60653`. They
are the same numbers on different dates: on 2026-05-04 the determination series
says 17.5157 and the settlement series says 17.4948 — a trade valued against the
first reconciles with nothing.

`SF60653` also **carries every calendar day forward**, where `SF43718` is simply
absent on weekends and holidays. Measured on 2026-08-26: over 2026 the
determination series has 164 rows and no weekend rows; the settlement series has
238 and 68. So *"the rate at the trade's date"* stops being banking-day
arithmetic and becomes `series[date]`.

**Two conventions in one table would have been worse than one wrong one**, so
the switch came with a decision on the ~8 determination-dated rows already
stored. Three ways out were considered — backfill, a column recording the series,
or re-fetching forward only. **Backfill won, and it is not the expensive option
the framing assumed:** the full series is 12,705 rows from 1991-11-14, returned
in a single free 493 KB request in 0.19 s. A column recording the series would
have made the ambiguity permanent to avoid overwriting eight rows.

**No delete was needed.** Because the settlement series covers every calendar
day, every determination-dated row falls inside it and the upsert corrects it in
place. `rake data:backfill_fx_history` is therefore idempotent and safe to
re-run.

Provenance follows [ADR-016](./0016-canonical-market-data-observations.md)'s
amendment: rows record `Banxico/SF60653`, not `Banxico`, because the sub-source
is what decides the number. `FxRateHistory.quote_on` returns the rate **with the
date and source of the row it used**, so no reader has to know which series
produced it — the FX endpoint used to hardcode the label and echo the date it was
asked for, which made the sheet's *"FIX de Banxico del …"* untrue on any
fallback.

## Revisit triggers

- A second non-USD/MXN currency pair becomes first-class (the resolver and history schema assume the USD/MXN axis is dominant).
- Backfill precision on pre-history snapshots becomes a real complaint (would justify importing a historical Banxico series instead of collecting forward only).
- The per-callsite `at_date:` discipline proves error-prone in practice (would justify pushing the date into a value object rather than a bare argument).
