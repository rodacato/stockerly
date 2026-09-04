# ADR-023 — A missing exchange rate absents the figure, and never fabricates one

- **Status:** Accepted
- **Date:** 2026-08-30, amended 2026-09-04
- **Author:** Adrian Castillo
- **Related:** [ADR-009](./0009-fx-history-strategy.md), [ADR-002](./0002-trading-marketdata-boundary.md), issues #494, #496, #537, `AUDIT-2026-08-30` UC-02, UC-06, HELP-01

---

## Context

`Portfolio#convert` raises `Trading::Domain::MissingFxRate` when no rate exists for the pair and
date it is asked for. What a caller should do about that was never decided in one place, so it was
decided again at every call site. Measured on `master` at 2026-08-30, the codebase gave **four
different answers**, plus three sites that gave none:

| Answer | Sites | Honest? |
|---|---|---|
| `nil` — the figure is absent | 6 (three `consolidated_summary`, `safe_gain`, `breakdown_for`, `by_market_value`) | Yes |
| `{}` — the collection is empty | 1 (`allocation_for`) | Yes |
| The amount in its own currency, ISO-prefixed | 1 (`position_amount`, per D10) | Yes, and the most useful |
| **`0`** | 2 (`value_of`, `value_today`) | **No** |
| Nothing — the exception propagates | 3 (`TimeWeightedReturn:67`, `ExternalFlows:49`, `HistoricalValuation:41`) | **No** |

The two zeros are not degradation, they are fabrication, and both are silent:

- `value_of` feeds the value chart. A zero draws a day on which the patrimony was worth nothing.
  Worse, `series_for` seeds `contributed` from the first snapshot's conversion, so a first-day
  failure zeroes the baseline and every later point in the contributed series with it.
- `value_today` sums the holdings for the buy-and-hold counterfactual. A holding that cannot
  convert contributes zero, understating `hold_return`, and since the screen shows
  `points: mine - hold_return`, **it reports that you beat buy-and-hold by more than you did.**
  It does not look broken. It looks flattering.

The three unguarded paths are worse in a different way: they answer a missing rate with a 500 on
`/portfolio` — the exact outcome `assets_helper`'s own comment calls unacceptable. They were not a
decision; they are the three call sites where nobody remembered, which is what a policy with no
home produces.

This stopped being theoretical when the setup wizard's seeded `USD→MXN = 17.25` was removed. That
invented number was what kept these paths cold: an instance always had *some* rate. Without it, a
fresh self-hosted instance has none until its first Banxico sync, and a reader holding dollars
meets all of them on first boot.

## Decision

**A figure that cannot be converted is absent. It is never zero, and it never takes the page down.**

Three outcomes, by layer:

1. **Writes refuse.** A persisted number whose unit cannot be established is rejected, not stored.
   `ExecuteTrade` and `Position#resync_from_trades!` already behave this way (#496, #497). A
   silently incomplete `avg_cost` is a number you stop being able to trust.
2. **Composite reads absent themselves.** A summary, a series, a comparison or an allocation that
   needs a rate it cannot get returns nothing, and the screen renders the `fx_unavailable` state
   that already exists for it. A partial composite is not offered: the alternative — showing it
   with a "partial" label — needs UI that does not exist and a trigger nobody has hit.
3. **A single row renders in its own currency.** Where one amount can stand alone, D10's fallback
   applies: show it with its ISO prefix rather than convert it. This is `position_amount`, and it
   is the best of the three because it loses nothing.

**The policy has one home:** `Trading::Domain::FxDegradation`. One instance per assembled screen;
every conversion that a screen can survive goes through `#figure`, which returns the caller's
fallback and remembers that it had to. `#degraded?` is what sets `fx_unavailable`, so the banner
now reflects *any* figure that had to absent itself rather than only the summary.

## Amendment 2026-09-04 — a rate from another date is a missing rate past seven days (#537)

The decision above covered the case where there is **no** rate. It did not cover the one where
there is a rate from the wrong date, and `Portfolio#historical_rate` had its own answer for that:

```ruby
FxRateHistory.rate_on(base: from, quote: to, date: date) || current_rate(from, to)
```

Two unbounded reaches, stacked. `quote_on` walks back to the newest row on or before the date with
no bound at all, and when that finds nothing the `||` falls **forward** to today's rate. A March
snapshot was valued at August's rate and presented as March's, with nothing marking it — which is
not a degraded figure, it is a different question answered.

**C1 Lucía Ramírez (Mexican financial domain):** *"El hueco de FIX es normal — fin de semana,
feriado, Jueves y Viernes Santo. Tomar el anterior más cercano es lo que hace un broker, y es lo que
liquida. Tomar el de hoy para una fecha de marzo es responder otra pregunta y no decirlo."*

**Decided:** a historical figure settles against the nearest **prior** rate within
`Portfolio::MAX_RATE_STALENESS_DAYS` (**7**), and absents itself past that under the policy above.
Seven days is sized on the longest legitimate hole in the series — Jueves Santo, Viernes Santo and
the weekend behind them, four days without a publication — with room for one missed publication on
either side. Inside the window the figure is not degraded and carries no marking: settling against
Friday's FIX on a Sunday is the convention, not an approximation. Outside it, the figure is absent
and `fx_unavailable` says so, which is the vocabulary this ADR already built rather than a second
one.

The forward fallback to `current_rate` is **removed**, not bounded. It was the fabricating half:
`current_rate` reads `fx_rates`, which holds one row per pair with no date, so it can only ever
answer "today" — there is no window in which today's rate is the right answer for a past date.
`current_rate` keeps its one honest caller, `convert` without an `at_date`.

Scoped to `Portfolio#historical_rate` deliberately. `FxRateHistory.quote_on` keeps its unbounded
walk-back because its other callers want it: `/fx_rates` renders `Quote#rate_date` and so already
tells the reader which date answered, and `Trading::Domain::ExecutionRate` is a write path governed
by outcome 1 above. Bounding the store would change trade entry as a side effect of a read fix.

`comun.sin_tc_cuerpo` moves from "el tipo de cambio del día" to "de alguna de las fechas" — the
banner can now fire for a hole in the past, and naming today would be false when it does.

## Consequences

- The two fabricated zeros are gone. The chart and the buy-and-hold comparison absent themselves.
- The three unguarded paths are guarded, so `/portfolio` no longer 500s without a rate. This was
  verified by running the new specs against the previous code: five of six failed with
  `MissingFxRate` propagating.
- `fx_unavailable` is now honest on three screens. Previously it was derived from the summary
  alone, so a screen whose summary converted but whose chart did not showed an empty chart and no
  explanation.
- The ordering fallback stays: when one row cannot be converted, the Activos list retreats to
  alphabetical rather than mixing currencies in one sort. A comparison you cannot make for one row
  is not a comparison you can make for the list.
- `position_amount` keeps its own `rescue`, deliberately. It is a per-row render decision with a
  different and better outcome, named here as outcome 3 rather than folded into `FxDegradation`.
- `AssembleHistorial` routes through the object but does not surface a banner: a closed position
  whose realised gain is absent renders as a dash today, and adding a banner there is UI nobody
  asked for. Recorded as the next candidate if it turns out to matter.

## Alternatives rejected

- **Keep the zeros.** Rejected: it is the same defect as the seeded 17.25 pointed the other way,
  and the buy-and-hold case is worse than a wrong number because it is a flattering one.
- **Let it raise and learn the real frequency.** Honest, and unacceptable on a daily driver: the
  answer would be measured in 500s on the dashboard.
- **Show partial figures with a label.** Better information, and it needs a "partial" concept
  across three screens plus copy for it. Revisit if the absent state proves annoying in practice.
- **A module-level rescue helper instead of an instance.** Rejected: it could not answer
  "did anything degrade on this screen?", which is what makes the banner honest.
