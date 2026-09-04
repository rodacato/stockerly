# The volatility-calibrated family, measured — 2026-09-04

Eight board cards descend from InvestAnswers' indicator set, and the research
card that fathers them states the debt plainly: *"none has been backtested
against our own data. What these models offer is decision structure, not edge.
Build them on that basis or not at all."*

This is that measurement. It settles what can be decided today, and names
precisely what blocks the rest — which turns out not to be a design question.

**Reproduce it:**

```bash
bin/prod-sync                                                        # docs/ops/prod-mirror.md
DATABASE_PREFIX=prodmirror bin/rails runner script/research/indicators.rb
DATABASE_PREFIX=prodmirror bin/rails runner script/research/confluence.rb
```

## The corpus, and what it can carry

Production holds **11,217 daily bars over 47 assets, 2025-08-29 to 2026-09-04** —
one year, because `BackfillPriceHistoryJob::DAYS` is 365. Every one of the 47 has
complete `high`/`low`, so ATR is computable everywhere.

One year is enough for some of these theses and not others, and the difference is
not a matter of degree:

| Thesis | Testable on this corpus | Why |
|---|---|---|
| 1 · ATR — volatility is asset-specific | **yes** | 47/47 assets, measured below |
| 2 · LILO layers | **partly** | the layers are arithmetic over ATR; DCAS needs the Mayer Multiple, which has 2.6 months of values for stocks |
| 3 · Confluence / mean reversion | **measured, confounded** | 117 episodes, but the rule version is starved — see below |
| 4 · Rotation (dual momentum) | **no** | a 12-month lookback over a 12-month window leaves zero rebalance points |
| 5 · Pairs / co-integration | **no** | needs long simultaneous series |

## Thesis 1 — the spread is a factor of ten, and it is the whole argument

ATR(14), Wilder's recursion, on the last closed bar of each asset:

| | ATR as % of price |
|---|---|
| ALAB | 7.49% |
| MRVL | 7.09% |
| MSTR | 5.66% |
| NVDA | 3.21% |
| BTC | 2.07% |
| SPY | 0.77% |
| VOO | 0.76% |

Mean by type: **stocks 3.79%, crypto 2.67%, ETFs 1.40%.**

A single threshold across that range is a threshold borrowed from a different
asset. A 3% move is a third of ALAB's ordinary day and four of SPY's. This is the
one claim in the family that needed no forward test to establish — it is a
property of the assets, and it is now measured rather than assumed.

Note the ordering, which contradicts the intuition the product might otherwise
encode: **crypto is calmer than the average stock in this portfolio.** The
holdings skew to high-beta names, so "crypto is the volatile one" is false here.

The implementation is Wilder's recursion, cross-checked against an independent
implementation written from the definition (NVDA, 254 bars: 7.339202 both ways).
A simple mean over the same window gives 7.2371 — 1.4% low, which is small until
it is multiplied by a layer index.

## Thesis 3 — the light has no sign of its own

Light 1 as the design defines it: `RSI(14) < 30 AND close < lower Bollinger band`.
Consecutive firings are collapsed into episodes, since their forward windows
overlap. Forward returns against the same assets' unconditional base rate:

| Horizon | Base rate | Oversold | Overbought |
|---|---|---|---|
| +5 days | +0.60% | **−0.33%** (n=73) | +2.01% (n=153) |
| +10 days | +1.17% | **−0.07%** (n=63) | +3.33% (n=134) |
| +20 days | +2.16% | +2.76% (n=60, win 57%) | +5.48% (n=112, win 50%) |

> **Corrected 2026-09-04.** The first run of this table used the RSI that shipped
> at the time, which was not Wilder's — see
> [`indicator-audit-2026-09.md`](indicator-audit-2026-09.md). Fixing the
> definition roughly halved the oversold episode count (109 → 60 at +20 days) and
> moved the light's returns down at every horizon. The conclusion below did not
> soften; it hardened.

Two things fall out immediately.

**At five and ten days the oversold light loses to doing nothing** (−0.33% and
−0.07% against base rates of +0.60% and +1.17%). Whatever it carries appears at
twenty trading days, and even there it barely clears the base rate.
The design's window — *"día 2 de ~3.5"*, with invalidation after a week — is
therefore wrong by roughly an order of magnitude. That number was invented; this
one is measured.

**The two lights are not mirrors.** Overbought beats oversold at 5 and 10 days
and decays to a coin flip at 20 (median +0.28%, win 50%). Rendering them as one
component in two colours implies a symmetry the data does not have.

### The finding that matters

Splitting the oversold episodes by the asset's own direction over the window:

| Horizon | On assets that rose | On assets that fell |
|---|---|---|
| +5 days | +2.00% (n=32, win 69%) | **−2.15%** (n=41, win 54%) |
| +10 days | +3.05% (n=28, win 71%) | **−2.57%** (n=35, win 40%) |
| +20 days | +7.16% (n=27, win 78%) | **−0.84%** (n=33, win 39%) |

The flat +2.76% is the average of two opposite behaviours. **The light does not
carry a sign of its own** — it means "buy the pullback" or "catch the knife"
depending entirely on a fact it does not contain.

This is exactly the argument for a confluence *vote* and against three chips
rendered side by side. `market/_confluence.html.erb` currently draws light 1 and
light 3 next to each other and never combines them; on this evidence that layout
invites reading "sobrevendido" as favourable in precisely the 30–40% of cases
where it lost 4–5%.

**This split is a diagnostic, not a rule.** It is computed from the asset's move
over the whole window, which includes each event's own future. It proves the
signal is not self-sufficient; it does not prove a real-time filter recovers it.

### The rule version is starved, and that is the real blocker

The same split asked with only what existed on the day:

| Filter | +20 days, above | +20 days, below |
|---|---|---|
| SMA(50) | +0.26% (**n=2**) | +3.42% (n=101) |
| SMA(200) | +10.76% (n=8, win 88%) | +1.71% (n=13, win 69%) |

**SMA(50) is collinear with the signal.** A bar that is oversold *and* below its
lower Bollinger band is essentially never above its 50-day average — 2 events out
of 133. It cannot serve as the independent confirmation a confluence needs.

**SMA(200) is the independent one**, and it points the same way as the diagnostic
split at every horizon. But it needs 200 bars *before* the event, and a 255-bar
series grants that eight times. n=8 is a direction, not a result.

## What this settles

**Build ATR (thesis 1).** The spread is measured and it is large. Every threshold
in the app that is currently global becomes per-asset with it — including the
per-asset volume threshold light 2 was given by the confluence panel, which has
no other way to be set.

**Do not close D3, and do not build the engine yet.** The measurement supports the
*premise* of a vote — the lights genuinely need each other — and cannot yet
support its *calibration*. The gate is no longer a design decision.

**Correct the designed window.** Whatever the engine ends up being, the artboard's
"~3.5 days" is contradicted by its own data.

**The blocker is the corpus, and it is fixable in production.**
`BackfillPriceHistoryJob::DAYS = 365` is what starves the SMA(200) test, kills
thesis 4 outright, and leaves the Mayer Multiple 2.6 months of values. Widening
it is one constant and a re-sync, and it is worth more than any of the eight
cards it unblocks.

## Honest limits

- **One regime.** The window rose: median asset +22.0%, SPY +22.2%. Dispersion is
  real — 11 of 42 assets fell and BTC lost 25.3% — which is why the direction
  split has any negative arm at all. But no conclusion here survives being called
  regime-independent.
- **In-sample.** Thresholds (30/70, 20×2σ) were chosen before the test and not
  fitted to it, which helps; nothing was held out, which does not.
- **Episodes are not independent across assets.** Forty-two holdings in a
  correlated market are fewer than forty-two experiments.
- **ADR-001's Support 3 still stands** and nothing here overturns it: daily-timeframe
  indicators rarely generate alpha for a retail investor on a weekly cadence. The
  case for building these remains decision structure, not edge.
