# ADR-014 — Reading a state out loud, from a closed catalogue

- **Status:** Accepted
- **Date:** 2026-08-25
- **Author:** Adrian Castillo (with review from the expert panel)
- **Amends:** [ADR-013](./0013-action-labels-on-persisted-observations.md), which amends [ADR-001](./0001-descriptive-not-prescriptive-language.md)
- **Related:** `design/DECISIONS.md` D3, D24, `design/CODE_CHANGES.md` §3

---

## Context

[ADR-013](./0013-action-labels-on-persisted-observations.md) (2026-08-24) allowed an action **verb**
when it is a deterministic function of a persisted `TechnicalObservation`. The asset-detail artboard
asks for more than a verb. Its verdict card reads:

> **Estirado — no es momento de comprar.** Si tienes, es zona de tomar ganancias parciales, no de
> entrar.

That is a sentence about timing, and it is conditioned on whether the reader holds the asset. ADR-013
does not cover it: a chip is one word from a lookup table, this is a paragraph with a judgement in it.

**This is the second widening of the same boundary in two days, and that deserves saying plainly.**
ADR-001 rejected a bounded prescriptive section precisely because *"in a solo project, the bounded
section becomes a loophole"*. Two amendments in two days is what the beginning of that loophole would
look like from the inside. The question is not whether this instance can be trusted — it is whether
the boundary being drawn is checkable by something other than good intentions.

### What has and has not changed since ADR-013

**Unchanged, and load-bearing:** the audience argument. [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md)
removed the friends beta; a self-hosted instance whose only user is its operator offers advice to
nobody. That reasoning covers a sentence exactly as well as it covers a word — it is about *who is
reading*, not about *how long the string is*.

**Also unchanged:** the empirical support. Daily-timeframe indicators rarely generate alpha. This ADR
does not permit a single new claim about the future.

**What actually differs** between a `vende` chip and "no es momento de comprar" is not the exposure.
It is that a chip obviously came from a table, and a sentence looks like it came from a mind. The
risk is that the *mechanism* stops being visible — that a phrase gets composed in a template one day
because it reads better, and nobody notices the difference.

So the mechanism is what this ADR pins down.

### Panel

- **S5 Ileana (Legal/Compliance MX):** her ADR-013 condition holds and is unchanged — the packaging
  must never present Stockerly as a service to third parties. Given that, sentence versus word is not
  a distinction the regulation makes.
- **C5 Renata (UX/copy):** the sentence is why the card works. "RSI 72" asks the reader to translate;
  "estirado, no es momento de comprar" is legible in the half-second the screen gets. Her condition:
  the reading it came from must stay on screen, so the sentence is never the only thing present.
- **C6 Esther (scope):** no new data, no new engine, no new job. A catalogue over rows that already
  exist. Her line, repeated from ADR-013: the moment a phrase needs a calculation that is not already
  persisted, it is a different feature and needs its own card.
- **C1 Lucía (Mexican financial domain):** her concern is staleness, again. A phrase in the present
  tense over a three-day-old observation is worse than a stale number, because prose does not look
  dated. The `observed_at` bound from ADR-013 must apply here too.

## Decision

**A state may be read out loud as a sentence, if and only if the sentence comes from a closed
catalogue in the domain, keyed by a state derived deterministically from persisted observations.**

### The rule, operationally

1. **The catalogue is data, not prose in a template.** Phrases live in one domain constant keyed by
   state. A template may select from it; it may never compose one.
2. **The state is derived, not judged.** It is a pure function of persisted `TechnicalObservation`
   rows and the indicator values in their snapshots. Given the same rows, the same state, always.
3. **The state set is closed and small.** Adding a state means adding a detector, the same bar
   ADR-013 set for adding a verb.
4. **The reading stays on screen** (Renata). The indicator that produced the state is rendered next
   to the sentence, never replaced by it.
5. **`observed_at` bounds it** (Lucía). A state derived from observations older than today is dated
   on screen or not shown. ADR-013's rule, restated because prose hides staleness better.

### ✅ Newly allowed

- A sentence naming a technical state and what it implies for timing, selected from the catalogue:
  *"Estirado — no es momento de comprar"*, *"zona de tomar ganancias parciales"*, *"considera vender"*.
- Conditioning on whether the reader holds the asset — the position is a fact the instance owns.

### ❌ Still forbidden — unchanged through ADR-001 and ADR-013

- **Probabilistic predictions** and **confidence-weighted forecasts**. Untouched by all three ADRs.
- **LLM-generated or free-form copy.** A catalogue entry is written once, by a person, and reviewed.
- **Phrases with no persisted observation behind them**, including anything composed at render time.
- **Portfolio-level advice** — "rebalancea", "sal de esta posición". Observations are per-asset.
- **Numbers invented to support a phrase.** If the sentence names a level, that level is persisted.

### How we will know if this became the loophole

ADR-001's fear was rationalization creep, so here is the test, written down while it is still cheap
to apply. **Any of these means the boundary failed and this ADR is reopened, not extended:**

- A phrase composed in a template or helper rather than selected from the catalogue.
- A state whose derivation reads anything other than persisted observations.
- A third amendment widening the same boundary. **Two is a decision; three is a pattern.**
- The catalogue growing without its detectors growing with it.

## Consequences

### Positive

- The asset detail can deliver its verdict card, which is the reason that screen exists.
- The mechanism stays visible and testable: a catalogue and a pure function, both covered by specs.
- ADR-001's and ADR-013's actual prohibitions survive intact.

### Negative

- **Stockerly now tells its reader when not to buy.** That is a real position, taken deliberately,
  and it is only defensible while the reader and the operator are the same person.
- The distance to a genuine recommendation engine is now shorter than it was two days ago. The
  closed catalogue and the closed state set are what hold that line; nothing else does.
- Three ADRs now govern one topic. If a fourth is ever needed, the right move is to supersede all
  three with one document rather than amend again.

### Follow-ups

- **Reopen before, not after, any return of a multi-user audience** — the same clause ADR-013 carries,
  and it now matters more.
- D3's confluence engine stays gated. Permitting a sentence about an existing state says nothing
  about computing a new signal.
