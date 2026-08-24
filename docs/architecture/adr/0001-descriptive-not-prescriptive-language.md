# ADR-001 — Stockerly speaks in descriptive language, never prescriptively

- **Status:** Accepted
- **Date:** 2026-05-14
- **Author:** Adrian Castillo (with review from the expert panel)
- **Supersedes:** —
- **Amended by:** [ADR-013](./0013-action-labels-on-persisted-observations.md) — action verbs are allowed when a persisted `TechnicalObservation` backs them; everything else here stands
- **Related:** [`docs/vision/audience.md`](../../vision/audience.md)

---

## Context

Across 22 development phases, Stockerly accumulated features with a prescriptive tone: a 5-factor TrendScore presented as a buy/sell "signal", Fear & Greed alerts tied to "time to take profits", Phase 22 LLM Insights generating portfolio rebalancing recommendations, weekly insights with "you should consider..." framing. None of those features started from a documented personal trigger and, per the retrospective audit of 2026-05-14, they were the primary drift vector of the product.

At the same time, the primary user (Adrian) confirms that he **does want** Stockerly to inform investment decisions using technical indicators (RSI, Bollinger Bands, moving averages, composite scores) and market-state interpretations ("oversold", "overbought", "concentrated").

The tension was initially framed as "observe vs. prescribe", but that was the wrong axis. The right axis is **descriptive language vs. prescriptive language**. A technical indicator interpreted in natural language (*"AAPL appears oversold per RSI(14)"*) is a perfectly valid observation; what is NOT valid is the action verb directed at the user (*"buy AAPL"*).

### Additional factors considered

1. **Moral liability.** The secondary audience is a closed beta with friends (≤20). If they act on a recommendation and lose money, it feels like Adrian's responsibility regardless of disclaimers. Damage to personal relationships isn't mitigated by a legal footer.
2. **Regulatory liability.** In Mexico, offering "financial advice" without a CNBV license is regulated. Observational language about public data does not qualify; personalized prescriptive language might.
3. **Empirical evidence.** Technical indicators on daily timeframes for retail investors on a weekly cadence rarely generate alpha. The utility is **context for reflection**, not **edge over the market**. Making the system "tell you what to do" when the data doesn't support that precision is engineering theater dressed as product.
4. **The hybrid anti-pattern.** An intermediate option ("default observational + a single bounded prescriptive section with strong disclaimer") was considered and rejected: in a solo project, the bounded section becomes a loophole. Any new feature gets rationalized as "it goes in that section with disclaimer".

---

## Decision

**Stockerly communicates to the user in descriptive language. The action verb always belongs to the user, never to the system.**

### Operational rules

#### ✅ Allowed

- **Events:** "X happened", "X changed", "X appears" — description of observable facts.
- **Position state:** "Your NVDA position dropped 18% from average cost in MXN".
- **Raw technical indicators:** "AAPL: RSI(14) = 28".
- **Linguistic interpretation of indicators:** "AAPL appears oversold per RSI(14)", "NVDA crossed below its MA200", "BMV in upper Bollinger Band breakout".
- **Observable composite indicators:** TrendScore (5-factor), Fear & Greed, Concentration HHI, Sharpe ratio, annualized volatility. Presented as **readings**, not **signals**.
- **Objective historical context:** "AAPL hasn't been at this RSI level since March 2024".

#### ❌ Forbidden

- **Action verbs directed at the user:** "buy", "sell", "rebalance", "exit", "enter", "consider selling", "time to...".
- **Probabilistic predictions:** "73% probability of going up this week", "high rebound probability".
- **Implicit timing recommendations:** "now is a good time to...", "worth considering...", "you could take advantage of...".
- **Confidence-weighted action forecasts:** model outputs that suggest action weighted by confidence.
- **Prescriptive section names:** "Suggestions", "Recommendations", "Actions to take". Use instead: "Observations", "Notable indicators today", "Technical analysis", "Portfolio context".

#### ⚠️ Gray zone (case-by-case review)

- **Comparative historical patterns:** "When AAPL has been at this RSI level before, it bounced within 2 weeks 60% of the time". Allowed as historical data if presented as **describing the past**, forbidden if it implies **predicting the future**.
- **Ratios and metrics with qualitative interpretation:** "P/E = 35, considered high vs. sector historical average". Allowed if the interpretation describes comparison, not action.

### Rule when in doubt

> *If the copy can be read as "the system tells you what to do", rewrite it. If it reads as "the system shows you what is happening", it's fine.*

If doubt persists after rewriting, escalate to the panel (C5 Renata for copy, C6 Esther for scope, C1 Lucía for domain validation).

---

## Consequences

### Positive

- **Clear, defensible scope.** Any feature proposal goes through the language filter. Reduces ambiguity about what to build.
- **Reduced moral liability with the closed beta.** Invited friends know the system describes; decisions remain theirs. Personal relationships aren't damaged by losses attributed to the system.
- **Alignment with statistical reality.** The system doesn't promise more than the evidence supports about retail TA on a weekly cadence.
- **Closes the primary drift vector.** The previous 22 phases accumulated prescriptive features. ADR-001 cuts that vector.

### Negative

- **Loss of superficial "wow factor".** A system that tells you "buy X" feels more active than one that describes state. Some beta friends might initially perceive Stockerly as "less intelligent".
- **Rewriting existing copy.** Phase 22 LLM Insights, TrendScore widgets, weekly insight, sentiment alerts — all require an audit and possible rewrite of strings and system prompts.
- **Discipline cost.** Every new feature requires attention to copy. Not high engineering cost, but constant overhead.

### Mitigations

- **The information is still there, only the tone changes.** Adrian (and the beta friends) infer actions from the observations. The system doesn't lose functionality, it loses imperative voice.
- **The "wow" is rebuilt with quality of observations**, not with the pretense of being an oracle. A rich, timely observation ("3 of your tech positions entered oversold simultaneously this week") is more valuable than a context-free "buy/sell".

---

## Implementation

### In existing code

| Feature | Action |
|---|---|
| TrendScore 5-factor | Keep the logic. Rewrite UI labels: from "Signal" to "Composite indicator". Remove "bullish/bearish signal" style copy if it exists. |
| Fear & Greed | Keep. Remove "time to take profits" copy. Present as a sentiment reading. |
| Weekly Insight | Audit the `WeeklyInsightCalculator`. Rewrite any prescriptive output. There was already an internal "observational only" note — formalize it via this ADR. |
| Phase 22 LLM Insights (Portfolio, News, Health, Earnings) | Rewrite system prompts to force descriptive tone. Add output validation against an action-verb blacklist. |
| Concentration alerts | Keep. Verify copy says "HHI = X, considered concentrated" not "you should diversify". |
| Sentiment alerts | Audit notification copy. |
| News sentiment badges | OK as is (descriptive badges: positive/neutral/negative). |

This audit runs in the **Sprint 1 code audit (Step 6)** and the concrete rewrites become backlog issues for subsequent sprints.

### In new code

- Any PR touching UI copy or LLM/system message output must self-review against this ADR.
- In gray zones, the reviewer asks: *"who is the subject of the action verb here?"*. If it's Stockerly, rewrite.

### In processes

- **Code review checklist:** a specific bullet for ADR-001.
- **Sprint QA:** one of the pre-close questions for each sprint is *"any new copy violates ADR-001?"*.
- **Beta onboarding:** explicitly communicate to invited friends that Stockerly describes, doesn't recommend; the system is not an investment advisor.

---

## Notes

- This ADR can be revisited if Stockerly transitions from personal/friends beta to a monetized product with a CNBV license or equivalent. Until then, it is a hard rule.
- The descriptive/prescriptive distinction is **of the product's language**, not the system's internal intelligence. The system can internally compute aggressive signals (e.g., "model says 87% probability of going up"); what changes is **how it's communicated to the user**.
- **Amended 2026-08-24 by [ADR-013](./0013-action-labels-on-persisted-observations.md).** The revisit
  clause above anticipated monetization with a CNBV licence. What actually happened was the opposite:
  [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md) removed the friends beta, so the
  audience whose losses this ADR protected stopped existing. ADR-013 narrows the ban to everything
  except an action verb derived from a persisted observation.
