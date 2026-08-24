# ADR-013 — Action-verb labels are allowed when a persisted observation backs them

- **Status:** Accepted
- **Date:** 2026-08-24
- **Author:** Adrian Castillo (with review from the expert panel)
- **Amends:** [ADR-001](./0001-descriptive-not-prescriptive-language.md) — most of it survives; see "What does not change"
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), `design/DECISIONS.md` D3, `design/CODE_CHANGES.md` §3

---

## Context

[ADR-001](./0001-descriptive-not-prescriptive-language.md) (2026-05-14) forbade action verbs
directed at the user. The 2.0 Panorama design draws exactly what it forbids: `compra` / `vende`
chips on the "Movimientos de interés" block, under the subtitle *"Oportunidades de compra y venta
hoy"*. The conflict was found during slice 3 rather than after it shipped.

ADR-001 rested on four supports. Three months later two of them have moved.

**Support 1 — moral liability — is gone with its audience.** ADR-001's own words: *"The secondary
audience is a closed beta with friends (≤20). If they act on a recommendation and lose money, it
feels like Adrian's responsibility."* [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md)
(2026-08-20) ran that beta, watched it fail, and dropped the audience. The people whose losses would
have been Adrian's fault are no longer users of Adrian's instance. This is not a weakened argument;
it is an argument whose subject no longer exists.

**Support 2 — regulatory liability — changes shape.** CNBV regulates *offering* investment advice.
A self-hosted instance whose only user is its operator offers nothing to anyone. The packaging
target (ADR-010) is a technical self-hoster who runs their **own** instance with their own keys and
their own data — closer to someone writing a formula in a spreadsheet than to someone receiving a
service. Nobody is being sold advice because nobody is being sold anything.

**Support 3 — empirical weakness of technical indicators — stands, untouched.** Daily-timeframe
indicators rarely generate alpha for a retail investor on a weekly cadence. That is precisely why
this ADR does not open the door to predictions.

**Support 4 — the hybrid anti-pattern — is the real objection**, and is answered below rather than
stepped around.

**The revisit clause fired on the wrong trigger, and that is worth saying plainly.** ADR-001's notes
allow reopening *"if Stockerly transitions from personal/friends beta to a monetized product with a
CNBV license"*. That is not what happened. The opposite happened: the product shed users rather than
gaining them, and shed the licence question with them. Reopening on an unanticipated trigger is a
weaker position than reopening on the planned one, so the argument has to carry itself on the facts
above rather than on the clause.

### Panel

- **S5 Ileana (Legal/Compliance MX):** the CNBV exposure was always about *offering*. With one
  operator per instance there is no offer and no client. Her condition: the packaging must never
  present Stockerly as a service to third parties — README and landing copy stay "run your own
  instance", not "get signals".
- **C1 Lucía (Mexican financial domain):** a `compra` chip over an RSI(14) reading is honest as long
  as it names a technical state and not a forecast. Her concern is the *silent* case — a chip that
  keeps showing yesterday's verb because nothing refreshed it. The observation carries `observed_at`;
  use it.
- **C5 Renata (UX/copy):** the verb is the reason the block works. `sobreventa` asks the reader to
  translate an indicator; `compra` is legible in the half-second the screen gets. She notes the chip
  must never be the only thing on the row — the phrase that produced it stays visible.
- **C6 Esther (scope):** no new engine, no new data, no new job. This is a label over rows that
  already exist. Her line: the moment a chip needs a calculation that is not already persisted, it
  is a different feature and needs its own card.

## Decision

**An action verb may be shown to the user if and only if it is a deterministic function of a
persisted `TechnicalObservation`. Everything ADR-001 forbade for any other reason stays forbidden.**

### The rule, operationally

- The chip's input is a row in `technical_observations` whose `observation_type` is in the closed
  `TechnicalObservation::TYPES` set. No row, no chip.
- The type → verb mapping lives in exactly one place and is covered by a spec. It is a lookup table,
  not a computation.
- The observation's `observed_at` is rendered with the chip or bounds it. A stale reading may not be
  presented as today's state.
- The phrase that produced the verb stays on the row. The chip summarizes an observation the user
  can still read.

### ✅ Newly allowed

- Action-verb chips over an observation: `compra` on `rsi_oversold_entered` / `bb_lower_breached`,
  `vende` on `rsi_overbought_entered` / `bb_upper_breached`.
- Section names that state the utility rather than hiding it: "Movimientos de interés",
  "Oportunidades de compra y venta hoy".

### ❌ Still forbidden — unchanged from ADR-001

- **Probabilistic predictions.** "73% probability of going up this week."
- **Confidence-weighted action forecasts**, and any LLM-generated recommendation.
- **Action verbs with no persisted observation behind them** — including a verb derived in a view,
  a helper, or a query at render time. The row must exist before the screen does.
- **Portfolio-level action verbs** — "rebalancea", "sal de esta posición". Observations are
  per-asset; nothing in the data backs a verb about the whole portfolio.
- **Implicit timing on anything else.** The allowance covers the observation chip and the block that
  holds it, not the rest of the product's copy.

### Why this is not the hybrid anti-pattern ADR-001 rejected

ADR-001 rejected "default observational + one bounded prescriptive section with a strong
disclaimer", reasoning that *"in a solo project, the bounded section becomes a loophole. Any new
feature gets rationalized as 'it goes in that section with disclaimer'."*

That reasoning is correct, and it applies to that boundary — which was **rhetorical**. A section
plus a disclaimer is a place, and anything can be put in a place.

This boundary is **verifiable in code**: a persisted row of a closed type, or no chip. An LLM
insight cannot be rationalized into it, because an LLM insight does not produce a
`TechnicalObservation`. Widening the allowance means adding a type to `TYPES` *and* writing the
detector that populates it — a visible, reviewable change to the domain, not a copy decision made
inside a template.

## Consequences

### Positive

- The Panorama can deliver the one distilled signal the 2.0 exists to give (`docs/vision/`, the
  second of the three failures ADR-010 names: "can't read indicators").
- The rule is checkable by a machine and by review, instead of by prose judgment per string.
- The rest of ADR-001 survives intact and keeps doing its job — which is most of what it was for.

### Negative

- **Stockerly now says "compra".** If Adrian loses money on a day it said so, the software said so.
  That is accepted deliberately, and it is the whole difference from the beta: the person who reads
  the verb is the person who chose to run the instance.
- The distance between a chip and a prediction is now one bad decision instead of a blanket ban. The
  `TYPES` set is what holds that line; widening it is where the discipline has to live.

### Follow-ups

- **Revisit before, not after, any return of a multi-user audience.** If Stockerly ever serves
  someone who did not install it, support 1 comes back and this ADR must be reopened first.
- The Radar's state chip ("neutral", "estirado") stays unbuilt. Its taxonomy exists nowhere in code,
  and this ADR does not create it — `trend_strength_label` measures a different thing.
- D3's confluence engine stays gated on its 4-filter card. Allowing a verb over an existing
  observation says nothing about building a new signal.
